# Add MicroK8s Worker Nodes with Traffic Shaping

This script provisions and joins multiple LXD containers as **MicroK8s worker nodes**, with randomized **bandwidth** and **latency** constraints to simulate heterogeneous network conditions.

## What It Does

For each new node:

- Launches a new LXD container based on `ubuntu:22.04`
- Installs MicroK8s
- Generates a unique join token from the master node
- Joins the node as a **MicroK8s worker**
- Applies **random traffic shaping**:
  - Bandwidth: 50–100 Mbps in 10 Mbps steps
  - Latency: 20–50 ms in 5 ms steps
- Adds a `systemd` unit to persist shaping rules across reboots
- Each container will have a `/etc/systemd/system/tc-shaping.service` created for persistence

## Usage

```bash
./add_microk8s_nodes.sh <basename> <count>
```

<basename>: Prefix for container names (e.g., edge)

<count>: Last index of nodes to create (starting from 2)

Example:

```bash
./add_microk8s_nodes.sh edge 6
```

This will create and join containers:

```bash
edge-2, edge-3, edge-4, edge-5, edge-6
```

## Network Constraints

Each container gets:

- Bandwidth limit: Randomly between 50 Mbps and 100 Mbps, in 10 Mbps steps
- Latency delay: Randomly between 20 ms and 50 ms, in 5 ms steps
- Applied using tc and netem on the container's eth0 interface
- Persisted using a systemd service inside the container