#!/bin/bash
#SBATCH --job-name=rclone_monitor
#SBATCH --begin=now
#SBATCH --dependency=singleton
#SBATCH --time=00:30:00
#SBATCH --mail-type=FAIL
#SBATCH --partition=service
#SBATCH --output=./runner_outputs/rclone_monitor.out
#SBATCH --open-mode=append
#SBATCH --mem-per-cpu=8000MB

sbatch $0

unset SLURM_MEM_PER_CPU
unset SLURM_MEM_PER_GPU
unset SLURM_MEM_PER_NODE

# Path to the rclone_monitor.sh script
RCLONE_MONITOR_SCRIPT="./rclone_monitor.sh"

# # Log file to record activity
# LOG_FILE="./runner_outputs/rclone_monitor_log.txt"

# Ensure the script exists
if [ ! -f "$RCLONE_MONITOR_SCRIPT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: $RCLONE_MONITOR_SCRIPT not found!" #>> "$LOG_FILE"
    exit 1
fi
echo "$(date '+%Y-%m-%d %H:%M:%S') - Executing rclone_monitor.sh"
# echo "$(date '+%Y-%m-%d %H:%M:%S') - Executing rclone_monitor.sh" #>> "$LOG_FILE"
bash "$RCLONE_MONITOR_SCRIPT" #>> "$LOG_FILE" #2>&1
echo "$(date '+%Y-%m-%d %H:%M:%S') - rclone_monitor.sh execution completed"