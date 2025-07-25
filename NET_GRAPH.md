# Generate Static Network Graph for LXD Cinc Cluster

This script generates a **static network topology** JSON file representing **bandwidth** and **latency** between LXD containers. It is useful for simulating or analyzing communication conditions in MicroK8s or other container-based testbeds.

## What It Does

- Iterates over all running LXD containers (`lxc list`)
- For every pair of containers (`A → B`):
  - Checks for an existing log file containing `bandwidth` and `latency` measurements
  - If file exists:
    - Parses measured values
  - If not:
    - Sets bandwidth and latency to `0`
- Generates a JSON file (`network_graph.json`) representing a complete graph with per-link constraints

## JSON Format

Example output structure:
```json
{
  "edge-1": {
    "edge-2": { "bandwidth_mbps": 80, "latency_ms": 30 },
    "edge-3": { "bandwidth_mbps": 90, "latency_ms": 25 }
  },
  "edge-2": {
    "edge-1": { "bandwidth_mbps": 80, "latency_ms": 30 },
    "edge-3": { "bandwidth_mbps": 70, "latency_ms": 40 }
  }
}
```

## Usage

```bash
./generate_network_graph.sh
```
The script will create or overwrite:
```bash
network_graph.json
```