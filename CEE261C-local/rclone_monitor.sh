#!/bin/bash

# Load Modules
module load system py-globus-cli
globus whoami
globus session show

# Define remote and local directories
## Define the commented in directories.sh
# REMOTE_SUBS_DIR="WeLabTeamDrive:/Courses/CEE261C-2025/SUBS/"
source directories.sh
LOCAL_DIR="SUBS"
DIR="$(pwd)/$LOCAL_DIR/"
TMP_DIR="./tmp/"
PREVIOUS_LIST="$LOCAL_DIR/rclone_previous_list.txt"
CURRENT_LIST="$TMP_DIR/rclone_current_list.txt"
OAK_UUID="8b3a8b64-d4ab-4551-b37e-ca0092f769a7"
GOOGLE_DRIVE_UUID="e1c8858b-d5aa-4e36-b97e-95913047ec2b"

# Ensure the local base directory exists
if [ ! -d "$LOCAL_DIR" ]; then
    mkdir -p "$LOCAL_DIR"
fi

# sync results to remote
echo "Copying $REMOTE_DIR to $DIR"
globus transfer "$GOOGLE_DRIVE_UUID:$REMOTE_DIR" "$OAK_UUID:$DIR" \
  --recursive \
  --include '*.sbin' \
  --include '*.stl' \
  --include 'responses*.txt' \
  --include 'kill*' \
  --include '*.json' \
  --exclude '*' \
  --sync-level checksum \
  --skip-source-errors \
  --notify failed,inactive \
  --label "Filtered transfer $(date +%Y%m%d-%H%M%S)"


# sync results to remote
echo "Copying $DIR to $REMOTE_DIR"
globus transfer "$OAK_UUID:$DIR" "$GOOGLE_DRIVE_UUID:$REMOTE_DIR" \
  --recursive \
  --include '*.sbin' \
  --include '*.README' \
  --include '*.comp(*' \
  --include 'surfer.log' \
  --include 'stitch.log' \
  --include 'charles.log' \
  --include '*.png' \
  --include 'slurm-*' \
  --exclude '*_VID_*.png*' \
  --exclude '*' \
  --sync-level checksum \
  --skip-source-errors \
  --notify failed,inactive \
  --label "Upload results $(date +%Y%m%d-%H%M%S)"
echo "RClone Monitor completed."

JOB_COUNT=0
MAX_JOBS=10
# Search recursively for response files files in folder and all subdirectories
find "$LOCAL_DIR" -type f -name "responses*.txt" -print | while read -r resp_file; do
    dir_path=$(dirname "$resp_file")
    flag_file="${resp_file}.submitted"

    # Check if the flag file exists
    if [[ -f "$flag_file" ]]; then
        continue
    fi

    # Process responses.txt
    if [[ "$resp_file" == *"responses.txt" ]]; then
        echo "Running process_responses.sh on $resp_file"
        bash ./process_responses.sh "$dir_path"
        JOB_COUNT=$((JOB_COUNT + 1))
    fi

    # Process responses_surfer.txt
    if [[ "$resp_file" == *"responses_surfer.txt" ]]; then
        echo "Running process_responses_surfer.sh on $resp_file"
        bash ./process_responses_surfer.sh "$dir_path"
        JOB_COUNT=$((JOB_COUNT + 1))
    fi

    # Create the submission flag
    touch "$flag_file"
    echo "Created submission flag: $flag_file"

    if [ "$JOB_COUNT" -gt "$MAX_JOBS" ]; then
        echo "More than $MAX_JOBS jobs submitted. Exiting."
        touch ./runner_outputs/rclone_monitor.kill  # Create the kill file
        exit 1
    fi

done

# Check for video files
./check_video_files.sh "createVideos2.tmp" "./SUBS"
