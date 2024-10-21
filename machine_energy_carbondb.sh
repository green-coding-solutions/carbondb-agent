#!/bin/env bash
set -euo pipefail

API_TOKEN='PLEASE_INPUT_YOUR_API_TOKEN'

while true; do

    # Clear tmp file
    echo -n > /tmp/machine_power.log

    source "$(dirname "$0")/hetzner_CAX21.sh"

    bash "$(dirname "$0")/cpu-utilization.sh" 60 > /tmp/machine_cpu_utilization.log

    while read -r read_var_time read_var_util; do
        echo "$read_var_time ${cloud_energy_hashmap[$read_var_util]}" | awk '{printf "%.9f\n", $1 * $2}' >> /tmp/machine_power.log
    done < /tmp/machine_cpu_utilization.log

    echo "On we go"

    # Since we poll every 1s Watts = Joules
    energy=$(awk '{s+=$1} END {print s}' /tmp/machine_power.log)
    energy=$(echo "scale=0; ($energy * 1000000) / 1" | bc) # microjoules

    # timestamp in microseconds
    timestamp=$(date +%s%6N)

    json_data=$(cat <<EOF
{
    "type": "machine.server",
    "machine": "Hetzner-CAX21",
    "project": "GMT-HOSTED-SERVICE",
    "tags": ["metrics.green-coding.io"],
    "time": "$timestamp",
    "energy_uj": "$energy"
}
EOF
)

    curl -X POST https://api.green-coding.io/v1/carbondb/add \
         -H "X-Authentication: ${API_TOKEN}" \
         -H "Content-Type: application/json" \
         -d "$json_data"

done
