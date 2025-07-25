#!/bin/bash

# Usage: ./add_microk8s_nodes.sh edge 6
# Adds edge-2 to edge-6 as MicroK8s worker nodes with random bandwidth and latency shaping

set -e

BASENAME=$1
COUNT=$2
MASTER_CONTAINER="master"

if [[ -z "$BASENAME" || -z "$COUNT" ]]; then
    echo "Usage: $0 <basename> <count>"
    exit 1
fi

for i in $(seq 1 "$COUNT"); do
    NAME="${BASENAME}-${i}"
    echo "🚀 Launching container: $NAME"
    lxc launch -p default -p microk8s ubuntu:22.04 "$NAME"

    echo "⏳ Waiting for $NAME to initialize networking..."
    sleep 10

    echo "🔧 Installing MicroK8s in $NAME"
    lxc exec "$NAME" -- sudo snap install microk8s --classic

    echo "🔐 Generating join command from master..."
    JOIN_CMD=$(lxc exec "$MASTER_CONTAINER" -- microk8s add-node | grep 'microk8s join' | head -n 1)

    echo "🔗 Joining $NAME to cluster with:"
    echo "$JOIN_CMD --worker"
    lxc exec "$NAME" -- sudo $JOIN_CMD --worker

    # Generate random bandwidth (50–100 Mbps) and latency (20–50 ms)
    BW=$(( (RANDOM % 6 + 5) * 10 ))  # 50, 60, ..., 100
    LAT=$(( (RANDOM % 7 + 4) * 5 ))  # 20, 25, ..., 50

    echo "🚦 Applying ${BW} Mbps / ${LAT} ms latency shaping inside $NAME"

    # Create shaping script inside container
    lxc exec "$NAME" -- bash -c "cat <<'EOF' | sudo tee /usr/local/bin/apply-tc.sh
#!/bin/bash
tc qdisc del dev eth0 root 2>/dev/null || true
tc qdisc add dev eth0 root handle 1: htb default 10
tc class add dev eth0 parent 1: classid 1:1 htb rate ${BW}mbit
tc class add dev eth0 parent 1:1 classid 1:10 htb rate ${BW}mbit
tc qdisc add dev eth0 parent 1:10 handle 20: netem delay ${LAT}ms
EOF"

    # Make the script executable
    lxc exec "$NAME" -- sudo chmod +x /usr/local/bin/apply-tc.sh

    # Create systemd service inside container
    lxc exec "$NAME" -- bash -c "cat <<EOF | sudo tee /etc/systemd/system/tc-shaping.service
[Unit]
Description=TC shaping for MicroK8s node
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/apply-tc.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF"

    # Enable and start service
    lxc exec "$NAME" -- sudo systemctl daemon-reexec
    lxc exec "$NAME" -- sudo systemctl daemon-reload
    lxc exec "$NAME" -- sudo systemctl enable --now tc-shaping.service

    echo "✅ $NAME joined the cluster with ${BW} Mbps / ${LAT} ms latency!"
    echo "---------------------------------------------"
done

echo "🎉 All nodes added and traffic shaping applied inside!"