#!/bin/env bash
set -euo pipefail

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

    # timestamp in microseconds
    timestamp=$(date +%s%N | cut -b1-16)

    json_data=$(cat <<EOF
[
  {
    "type": "machine.test",
    "company": "20b269ce-cd67-4788-8614-030eaf5a0b47",
    "machine": "6662e9b9-2daa-4177-a5c3-20af79567a66",
    "project": "00000001-BCA5-451B-9E60-3A2FD07FA28D",
    "tags": "metrics.green-coding.io",
    "time_stamp": "$timestamp",
    "energy_value": "$energy"
  }
]
EOF
)

    curl -X POST https://api.green-coding.io/v1/carbondb/add \
    	-H "Content-Type: application/json" \
    	-d "$json_data"

done
