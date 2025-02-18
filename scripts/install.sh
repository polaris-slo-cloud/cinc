#!/bin/bash

set -e  # Exit on error

[ "$(id -u)" -ne 0 ] && echo "This script must be run as root (use sudo)." && exit 1

# Define LXC cluster name and container node name
LXC_CLUSTER_NAME="microk8s-cluster"
LXC_CONTAINER_NAME="master"

# Function to detect the primary network interface and node IP
detect_primary_iface() {
    IFACE=$(ip -o -4 route show to default | awk '{print $5}')
    NODE_IP=$(hostname -I | awk '{print $1}')
    echo "Detected primary interface: $IFACE"
    echo "Detected node IP address: $NODE_IP"
}

# Function to detect existing LXC network bridge
detect_lxc_bridge() {
    LXC_BRIDGE=$(lxc network list | awk '/bridge/ && /YES/ {print $2}' | head -n 1)
    if [ -z "$LXC_BRIDGE" ]; then
        LXC_BRIDGE="lxdfan0"
        echo "No existing LXC bridge found. Defaulting to: $LXC_BRIDGE"
    else
        echo "Detected LXC bridge: $LXC_BRIDGE"
    fi
}

# Enable IP forwarding
enable_ip_forwarding() {
    echo "Enabling IP forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-lxc-forwarding.conf
    sudo sysctl --system
}

# Install LXD (Snap package)
install_lxd() {
    echo "Installing LXD..."
    sudo apt update
    sudo apt install -y snapd wget iptables
    sudo snap install lxd
}


# Initialize LXD cluster with minimal configuration
initialize_lxd_cluster() {
    echo "Initializing LXD cluster ($LXC_CLUSTER_NAME)..."

    # Get node IP
    SUBNET_RANGE="${NODE_IP%.*}.0/24"  # Dynamically sets subnet based on NODE_IP
	SERVER_NAME=$(hostname)
    # Check if LXD cluster is already initialized
    if lxc cluster list 2>/dev/null | grep -q "database-leader"; then
        echo "LXD cluster ($LXC_CLUSTER_NAME) already exists."
    else
        sudo lxd init --preseed <<EOF
config:
  cluster.https_address: "$NODE_IP:8443"
  core.https_address: "$NODE_IP:8443"
networks:
- name: $LXC_BRIDGE
  type: bridge
  config:
    bridge.mode: fan
    fan.underlay_subnet: "$SUBNET_RANGE"
    ipv4.nat: "true"
storage_pools:
- name: local
  driver: dir
profiles:
- config: {}
  description: Default LXD profile
  devices:
    eth0:
      name: eth0
      network: lxdfan0
      type: nic
    root:
      path: /
      pool: local
      type: disk
  name: default  
cluster:
  enabled: true
  server_name: "$SERVER_NAME"
  server_address: "$NODE_IP"
EOF
        echo "LXD cluster ($LXC_CLUSTER_NAME) initialized with subnet $SUBNET_RANGE."
    fi
}

# Setup IPTables rules for LXC networking
setup_iptables_rules() {
    echo "Configuring iptables rules..."

    # Accept traffic from LXC bridge
    sudo iptables -A INPUT -i "$LXC_BRIDGE" -j ACCEPT
    
    # Allow forwarding between LXC bridge and external network
    sudo iptables -A FORWARD -i "$LXC_BRIDGE" -o "$IFACE" -j ACCEPT
    sudo iptables -A FORWARD -i "$IFACE" -o "$LXC_BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    # NAT outgoing traffic from LXC containers
    sudo iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o "$IFACE" -j MASQUERADE
    
    echo "Saving iptables rules..."
    sudo iptables-save | sudo tee /etc/iptables.rules

    echo "Applying rules on boot..."
    echo -e "#!/bin/sh\niptables-restore < /etc/iptables.rules" | sudo tee /etc/network/if-pre-up.d/iptables
    sudo chmod +x /etc/network/if-pre-up.d/iptables
}


install_microk8s() {
    echo "🚀 Installing MicroK8s in LXD container ($LXC_CONTAINER_NAME)..."

    # Ensure MicroK8s LXD profile exists
    if ! lxc profile list | grep -q "microk8s"; then
        echo "📌 Creating LXD profile for MicroK8s..."
        lxc profile create microk8s
    fi

    # Detect filesystem type (ZFS or ext4)
    FS_TYPE=$(df -T / | tail -1 | awk '{print $2}')
    echo "📂 Detected filesystem type: $FS_TYPE"

    # Download the appropriate profile
    if [ "$FS_TYPE" == "zfs" ]; then
        PROFILE_URL="https://raw.githubusercontent.com/ubuntu/microk8s/master/tests/lxc/microk8s-zfs.profile"
    else
        PROFILE_URL="https://raw.githubusercontent.com/ubuntu/microk8s/master/tests/lxc/microk8s.profile"
    fi

    echo "🔽 Downloading MicroK8s LXD profile..."
    wget -q "$PROFILE_URL" -O microk8s.profile

    # Apply the profile
    echo "🔄 Applying MicroK8s LXD profile..."
    cat microk8s.profile | lxc profile edit microk8s
    rm microk8s.profile

    # Launch LXD container with MicroK8s profile
    echo "🚀 Launching LXD container ($LXC_CONTAINER_NAME) for MicroK8s..."
    if ! lxc list | grep -q "$LXC_CONTAINER_NAME"; then
        lxc launch -p default -p microk8s ubuntu:20.04 "$LXC_CONTAINER_NAME"
        echo "⏳ Waiting for container initialization..."
        sleep 15  # Give time for container setup
    else
        echo "✅ Container ($LXC_CONTAINER_NAME) already exists."
    fi

    # Install MicroK8s inside the container
    echo "📦 Installing MicroK8s in container..."
    lxc exec "$LXC_CONTAINER_NAME" -- sudo snap install microk8s --classic

    # Configure AppArmor profiles for MicroK8s
    echo "🛡️ Configuring AppArmor in the container..."
    lxc exec "$LXC_CONTAINER_NAME" -- bash -c "cat > /etc/rc.local <<EOF
#!/bin/bash
apparmor_parser --replace /var/lib/snapd/apparmor/profiles/snap.microk8s.*
exit 0
EOF"

    # Make rc.local executable
    lxc exec "$LXC_CONTAINER_NAME" -- chmod +x /etc/rc.local

    echo "🎉 MicroK8s setup in LXD container ($LXC_CONTAINER_NAME) is complete!"
}



# Main execution
detect_primary_iface
detect_lxc_bridge
enable_ip_forwarding
install_lxd
initialize_lxd_cluster
setup_iptables_rules
install_microk8s


echo "LXC cluster ($LXC_CLUSTER_NAME) setup with container node ($LXC_CONTAINER_NAME) is complete! 🎉"
