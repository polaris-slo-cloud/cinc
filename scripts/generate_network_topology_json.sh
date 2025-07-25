#!/bin/bash

OUT_FILE="network_topology.json"
TMP_DATA="__netinfo.tmp"
> "$TMP_DATA"

echo "📦 Collecting node list..."
NODES=($(lxc list -c n --format csv))

echo "🧠 Gathering tc shaping data from each node..."
for NODE in "${NODES[@]}"; do
    echo "  🔍 $NODE"

    BW=$(lxc exec "$NODE" -- bash -c "tc class show dev eth0 2>/dev/null | grep -oP 'rate \K[0-9]+' | head -n1")
    LAT=$(lxc exec "$NODE" -- bash -c "tc qdisc show dev eth0 2>/dev/null | grep -oP 'delay \K[0-9]+' | head -n1")

    BW=${BW:-0}   # Default to 0 Mbps if not found
    LAT=${LAT:-0} # Default to 0 ms if not found

    echo "$NODE $BW $LAT" >> "$TMP_DATA"
done

echo "📡 Generating fully connected topology..."
echo '{' > "$OUT_FILE"
echo '  "nodes": [' >> "$OUT_FILE"
for NODE in "${NODES[@]}"; do
    echo "    \"$NODE\"," >> "$OUT_FILE"
done | sed '$s/,$//' >> "$OUT_FILE"
echo '  ],' >> "$OUT_FILE"

echo '  "edges": [' >> "$OUT_FILE"
for SRC in "${NODES[@]}"; do
    for DST in "${NODES[@]}"; do
        if [[ "$SRC" != "$DST" ]]; then
            BW_SRC=$(grep "^$SRC" "$TMP_DATA" | awk '{print $2}')
            LAT_SRC=$(grep "^$SRC" "$TMP_DATA" | awk '{print $3}')
            echo "    {\"source\": \"$SRC\", \"target\": \"$DST\", \"bandwidth_mbps\": $BW_SRC, \"latency_ms\": $LAT_SRC}," >> "$OUT_FILE"
        fi
    done
done | sed '$s/,$//' >> "$OUT_FILE"
echo '  ]' >> "$OUT_FILE"
echo '}' >> "$OUT_FILE"

rm "$TMP_DATA"
echo "✅ Topology saved to $OUT_FILE"
