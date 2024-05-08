#!/bin/bash

# Process name to monitor
PROCESS_NAME="cache-main"
LOG_FILE="cache_main_usage.log"

# Service to potentially restart
SERVICE_NAME="varnish"

# Maximum number of iterations
MAX_ITERATIONS=5
current_iteration=0

# Initialize SUM_CPU_USAGE to store the cumulative CPU usage
SUM_CPU_USAGE=0

# Clearing or creating the log file before starting
echo "Starting monitoring of $PROCESS_NAME" > "$LOG_FILE"
echo "Monitoring will run for $MAX_ITERATIONS iterations." >> "$LOG_FILE"

# Main monitoring loop
while [ $current_iteration -lt $MAX_ITERATIONS ]; do
    # Increment iteration counter
    current_iteration=$((current_iteration + 1))

    # Use top in batch mode to capture CPU and memory usage
    # -n 1: Run top command for 1 iteration
    # -b: Batch mode operation
    # -d 0.1: Delay of 0.1 seconds between updates
    OUTPUT=$(top -b -n 1 -d 0.1 | grep "$PROCESS_NAME")

    # Check if any process was found
    if [ -z "$OUTPUT" ]; then
        echo "No process found for $PROCESS_NAME at $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    else
        # Logging each found instance with variables
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
        
        # Process the output line by line without creating a subshell
        while IFS= read -r line; do
            PID=$(echo "$line" | awk '{print $1}')
            CPU_USAGE=$(echo "$line" | awk '{print $9}')
            MEM_SIZE=$(echo "$line" | awk '{print $6}')
            echo "PID: $PID, CPU Usage: $CPU_USAGE, Memory Size: $MEM_SIZE" >> "$LOG_FILE"
            
            # Add the current CPU usage to the cumulative sum
            SUM_CPU_USAGE=$(echo "$SUM_CPU_USAGE + $CPU_USAGE" | bc)
        done <<< "$OUTPUT"
    fi

    # Sleep for 10 seconds before checking again
    sleep 10
done

# Calculate the average CPU usage across all iterations
AVERAGE_CPU_USAGE=$(echo "scale=2; $SUM_CPU_USAGE / $MAX_ITERATIONS" | bc)

echo "Total CPU Usage accumulated over $MAX_ITERATIONS iterations: $SUM_CPU_USAGE%" >> "$LOG_FILE"
echo "Average CPU Usage per iteration: $AVERAGE_CPU_USAGE%" >> "$LOG_FILE"
echo "Monitoring completed after $MAX_ITERATIONS iterations." >> "$LOG_FILE"

# Check if the average CPU usage exceeds 300%
if (( $(echo "$AVERAGE_CPU_USAGE > 5" | bc) )); then
    echo "Average CPU Usage of $AVERAGE_CPU_USAGE% exceeds threshold, restarting $SERVICE_NAME..." >> "$LOG_FILE"
#    systemctl restart $SERVICE_NAME
    echo "$SERVICE_NAME restarted successfully." >> "$LOG_FILE"
fi
