<p align="left">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;✨&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;⭐&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.<br>
⭐&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;⭐&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.<br>
&nbsp;&nbsp;.&nbsp;&nbsp;⭐&nbsp;&nbsp;&nbsp;⭐&nbsp;&nbsp;&nbsp;⭐&nbsp;&nbsp;.&nbsp;&nbsp;<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;⭐&nbsp;&nbsp;<b>ORION</b>&nbsp;&nbsp;&nbsp;.<br>
⭐&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;⭐&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;⭐&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;⭐&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.<br>
&nbsp;&nbsp;.&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;✨&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.<br>
</p>

Welcome to CinC 🚀  

## CinC - Distributed Serverless Simulator

## Overview
This project provides an automated script to set up a **distributed serverless simulator** using **LXD containers** and **MicroK8s**. Each node in the cluster runs inside an LXD container and serves as a functional part of the serverless simulation environment. The setup is fully automated, including networking, container initialization, and Kubernetes deployment.

## Features
- **Automated LXD Cluster Creation**: Sets up a new **LXD cluster** with dynamic networking and storage.
- **MicroK8s Integration**: Deploys a **lightweight Kubernetes environment** in an isolated container.
- **Dynamic Network Configuration**: Uses LXD's **fan networking** to enable cross-node communication.
- **Automatic Node Detection**: The system dynamically detects the node's **IP, subnet, and hostname**.
- **Secure and Scalable**: Supports additional nodes joining the cluster seamlessly.

## Prerequisites
Before running this script, ensure that:
- The host machine runs **Ubuntu 20.04+**.
- **LXD and Snap** are installed.
- **Sudo privileges** are available.

## Installation
1. **Clone the repository or copy the script**:
   ```bash
   git clone <repository-url>
   cd <repository-folder>
   ```
2. **Make the script executable**:
   ```bash
   chmod +x setup_simulator.sh
   ```
3. **Run the script as root (or use sudo)**:
   ```bash
   sudo ./setup_simulator.sh
   ```

## Components
### 1. LXD Cluster Setup
- Detects primary network interface and assigns a subnet.
- Configures **IP forwarding** and **iptables rules**.
- Initializes an LXD cluster using a dynamically generated configuration.

### 2. MicroK8s Deployment
- Creates a specialized **LXD profile** for MicroK8s.
- Downloads and applies the correct MicroK8s profile (**ZFS or EXT4** support).
- Launches a new **LXD container** running **MicroK8s**.
- Configures **AppArmor profiles** to ensure smooth operation.

## Usage
After running the script, your distributed serverless simulator will be up and running. You can interact with the environment as follows:

### **Check LXD Cluster Status**
```bash
lxc cluster list
```

### **Verify Running Containers**
```bash
lxc list
```

### **Enter the MicroK8s Container**
```bash
lxc exec master -- bash
```

### **Check MicroK8s Status**
```bash
lxc exec master -- microk8s status --wait-ready
```

## Extending the Cluster
To add more nodes, use:
```bash
lxc cluster add <node-name>
```
Then, join the new node with the generated token.

## Cleanup
To remove the cluster and containers:
```bash
lxc delete master --force
lxc profile delete microk8s
lxd recover
```

## Future Enhancements
- **Multi-node scaling** with automatic joining.
- **Integration with Knative** for full serverless workflows.
- **Metrics and Logging** via Prometheus and Grafana.

## License
This project is open-source and follows the MIT License.

---

🚀 **Now you're ready to build and experiment with a distributed serverless environment!**
