#!/bin/bash

set -e  # Exit on error

echo "Starting LXC & LXD uninstallation..."

# Function to detect the primary network interface
detect_primary_iface() {
    IFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n 1)
    echo "Detected primary interface: $IFACE"
}

# Function to detect existing LXC network bridge
detect_lxc_bridge() {
    LXC_BRIDGE=$(lxc network list | awk '/bridge/ && /YES/ {print $1}' | head -n 1)
    if [ -z "$LXC_BRIDGE" ]; then
        LXC_BRIDGE="lxcbr0"
        echo "No existing LXC bridge found. Defaulting to: $LXC_BRIDGE"
    else
        echo "Detected LXC bridge: $LXC_BRIDGE"
    fi
}

# Stop and remove all LXC containers
remove_lxc_containers() {
    echo "Stopping and deleting all LXC containers..."
    for container in $(lxc list --format csv -c n); do
        echo "Removing container: $container"
        lxc stop "$container" --force || true
        lxc delete "$container" || true
    done
}

# Remove all LXC networks
remove_lxd_networks() {
    echo "Removing all LXC networks..."
    for network in $(lxc network list --format csv -c n); do
        echo "Deleting network: $network"
        lxc network delete "$network" || true
    done
}

# Remove LXD completely
uninstall_lxd() {
    echo "Uninstalling LXD..."
    sudo snap remove lxd || true
    sudo apt autoremove -y
}

# Remove iptables rules
remove_iptables_rules() {
    echo "Removing iptables rules related to LXC..."
    sudo iptables -D INPUT -i "$LXC_BRIDGE" -j ACCEPT || true
    sudo iptables -D FORWARD -i "$LXC_BRIDGE" -o "$IFACE" -j ACCEPT || true
    sudo iptables -D FORWARD -i "$IFACE" -o "$LXC_BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT || true
    sudo iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o "$IFACE" -j MASQUERADE || true

    echo "Saving iptables rules..."
    sudo iptables-save | sudo tee /etc/iptables.rules
}

# Main execution
detect_primary_iface
detect_lxc_bridge
remove_lxc_containers
remove_lxd_networks
uninstall_lxd
remove_iptables_rules

echo "LXD and all related configurations have been removed! 🎉"
