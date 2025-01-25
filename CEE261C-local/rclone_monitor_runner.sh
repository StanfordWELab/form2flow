#!/bin/bash

# Path to the rclone_monitor.sh script
RCLONE_MONITOR_SCRIPT="./rclone_monitor.sh"

# Log file to record activity
LOG_FILE="./runner_outputs/rclone_monitor_log.txt"

# Local PID file (stored in user's home directory)
PID_FILE="./runner_outputs/rclone_monitor.pid"

# Kill file to trigger a graceful exit
KILL_FILE="./runner_outputs/rclone_monitor.kill"

# Ensure the script exists
if [ ! -f "$RCLONE_MONITOR_SCRIPT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: $RCLONE_MONITOR_SCRIPT not found!" >> "$LOG_FILE"
    exit 1
fi

# Prevent multiple instances
if [ -f "$PID_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Another instance is already running." >> "$LOG_FILE"
    exit 1
fi

# Create a PID file
echo $$ > "$PID_FILE"

# Trap signals to remove the PID file on exit
trap 'rm -f "$PID_FILE"; exit' SIGINT SIGTERM EXIT

echo "$(date '+%Y-%m-%d %H:%M:%S') - Started rclone monitor loop" >> "$LOG_FILE"

# Infinite loop to run the rclone monitor script every minute
while true; do
    # Check if the kill file exists
    if [ -f "$KILL_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Kill file detected! Stopping script." >> "$LOG_FILE"
        rm -f "$PID_FILE"
        rm -f "$KILL_FILE"  # Optionally remove the kill file
        exit 0
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Executing rclone_monitor.sh" >> "$LOG_FILE"
    bash "$RCLONE_MONITOR_SCRIPT" >> "$LOG_FILE" 2>&1
    sleep 60  # Wait for 1 minute
done
