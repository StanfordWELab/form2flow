#!/bin/bash

# Log file path
LOG_FILE="time_log.txt"

# Infinite loop to write the current date every minute
while true; do
    echo "Current Time: $(date)" >> "$LOG_FILE"
    sleep 60  # Wait for 1 minute
done