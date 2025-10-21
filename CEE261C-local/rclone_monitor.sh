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
SUBDIR="HW4"

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
echo "Copying $REMOTE_SUBS_DIR to $LOCAL_DIR"
rclone copy "$REMOTE_SUBS_DIR" "$LOCAL_DIR" \
    --filter "+ **/${SUBDIR}/**/*.sbin" \
    --filter "+ **/${SUBDIR}/**/*.stl" \
    --filter "+ **/${SUBDIR}/**/responses*.txt" \
    --filter "+ **/${SUBDIR}/**/kill*" \
    --filter "+ **/${SUBDIR}/**/*.json" \
    --filter "- *" \
    --skip-links \
    --stats-one-line \
    --tpslimit 10 \
    --drive-pacer-min-sleep 200ms \
    --drive-pacer-burst 5 \
    --verbose \
    --ignore-existing \
    --fast-list

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

    # Process responses_surfer.txt
    if [[ "$resp_file" == *"responses_surfer.txt" ]]; then
        echo "Running process_responses_surfer.sh on $resp_file"
        bash ./process_responses_surfer.sh "$dir_path"
        JOB_COUNT=$((JOB_COUNT + 1))
    fi

    # Process responses.txt
    if [[ "$resp_file" == *"responses.txt" ]]; then
        echo "Running process_responses.sh on $resp_file"
        bash ./process_responses.sh "$dir_path"
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

# sync killfiles to remote
echo "Copying killfiles from $REMOTE_RESULTS_DIR to $LOCAL_DIR"
rclone copy "$REMOTE_RESULTS_DIR" "$LOCAL_DIR" \
    --filter "+ **/${SUBDIR}/**/kill*" \
    --filter "- *" \
    --skip-links \
    --stats-one-line \
    --tpslimit 10 \
    --drive-pacer-min-sleep 200ms \
    --drive-pacer-burst 5 \
    --verbose \
    --ignore-existing \
    --fast-list

# sync remote to drive
echo "Copying $LOCAL_DIR to $REMOTE_RESULTS_DIR"
rclone copy "$LOCAL_DIR" "$REMOTE_RESULTS_DIR" \
    --filter "- **/${SUBDIR}/**/*_VID_*.png*" \
    --filter "+ **/${SUBDIR}/**/*.sbin" \
    --filter "+ **/${SUBDIR}/**/*.README" \
    --filter "+ **/${SUBDIR}/**/*.comp(*" \
    --filter "+ **/${SUBDIR}/**/surfer.log" \
    --filter "+ **/${SUBDIR}/**/stitch.log" \
    --filter "+ **/${SUBDIR}/**/charles.log" \
    --filter "+ **/${SUBDIR}/**/*.png" \
    --filter "+ **/${SUBDIR}/**/slurm-*" \
    --filter "+ **/${SUBDIR}/**/*.txt" \
    --filter "+ **/${SUBDIR}/**/*.mp4" \
    --filter "+ **/${SUBDIR}/**/*.pdf" \
    --filter "+ **/${SUBDIR}/**/*.html" \
    --filter "- *" \
    --skip-links \
    --stats-one-line \
    --tpslimit 10 \
    --drive-pacer-min-sleep 200ms \
    --drive-pacer-burst 5 \
    --log-level ERROR \
    --fast-list
    # --no-traverse
    # --update \
    # --check-first
    # --progress
echo "Rclone sync completed."
