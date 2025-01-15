#!/bin/bash

# Path to the rclone_monitor.sh script
RCLONE_MONITOR_SCRIPT="./rclone_monitor.sh"

# Log file to record activity
LOG_FILE="rclone_monitor_log.txt"

# Ensure the script exists
if [ ! -f "$RCLONE_MONITOR_SCRIPT" ]; then
    echo "Error: $RCLONE_MONITOR_SCRIPT not found!" >> "$LOG_FILE"
    exit 1
fi

# Infinite loop to run the rclone monitor script every minute
while true; do
    echo "Executing rclone_monitor.sh at $(date)" >> "$LOG_FILE"
    bash "$RCLONE_MONITOR_SCRIPT" >> "$LOG_FILE" 2>&1
    sleep 60  # Wait for 1 minute
done

