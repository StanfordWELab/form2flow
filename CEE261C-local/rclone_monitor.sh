#!/bin/bash

# Define remote and local directories
REMOTE_SUBS_DIR="WeLabTeamDrive:/Courses/CEE261C-2025/SUBS/"
REMOTE_RESULTS_DIR="WeLabTeamDrive:/Courses/CEE261C-2025/HW/"
LOCAL_DIR="./SUBS/"
PREVIOUS_LIST="$LOCAL_DIR/rclone_previous_list.txt"
CURRENT_LIST="/tmp/current_list.txt"

# Ensure the local base directory exists
if [ ! -d "$LOCAL_DIR" ]; then
    mkdir -p "$LOCAL_DIR"
fi

# Ensure the previous list file exists
if [ ! -f "$PREVIOUS_LIST" ]; then
    touch "$PREVIOUS_LIST"
fi

# Fetch the current file list from the remote directory using checksum
rclone ls --checksum "$REMOTE_SUBS_DIR" | sort > "$CURRENT_LIST"

# Compare the current list with the previous list to find new entries
CHANGES=$(diff --changed-group-format='%>' --unchanged-group-format='' "$PREVIOUS_LIST" "$CURRENT_LIST")

if [ -n "$CHANGES" ]; then
    echo "Changes detected. Copying updated files..."

    # Extract the list of new or updated items
    echo "$CHANGES" | awk '{print $2}' > /tmp/new_items.txt

    # Process each new or updated file/folder
    while IFS= read -r ITEM; do
        echo "Processing $ITEM..."
        
        # Determine the local path for the item
        LOCAL_PATH="$LOCAL_DIR$ITEM"
        REMOTE_PATH="$REMOTE_SUBS_DIR$ITEM"
        
        # Ensure the local directory structure exists
        LOCAL_DIR_PATH=$(dirname "$LOCAL_PATH")
        if [ ! -d "$LOCAL_DIR_PATH" ]; then
            echo "Creating directory: $LOCAL_DIR_PATH"
            mkdir -p "$LOCAL_DIR_PATH"
        fi

        # Copy the new or updated file/folder
        echo "Copying $REMOTE_PATH to $LOCAL_DIR_PATH"
        rclone copy --progress "$REMOTE_PATH" "$LOCAL_DIR_PATH"

        # Check if the copied file is an .stl file
        if [[ "$ITEM" == *.stl ]]; then
            FOLDER_PATH=$(dirname "$LOCAL_PATH")
            if [[ "$(basename "$LOCAL_PATH")" != "building.stl" ]]; then
                echo "Renaming STL file: $ITEM"
                mv "$LOCAL_PATH" "$FOLDER_PATH/building.stl"
            else
                echo "STL file already named 'building.stl', skipping rename."
            fi
        fi
        
    done < /tmp/new_items.txt

    while IFS= read -r ITEM; do
        # Check if the copied file is responses.txt and process it
        if [[ "$ITEM" == *"responses.txt" ]]; then
            FOLDER_PATH=$(dirname "$LOCAL_PATH")
            echo "Running process_responses.sh on $FOLDER_PATH"
            bash ./process_responses.sh "$FOLDER_PATH"
        fi

        # Check if the copied file is responses_surfer.txt and process it
        if [[ "$ITEM" == *"responses_surfer.txt" ]]; then
            FOLDER_PATH=$(dirname "$LOCAL_PATH")
            echo "Running process_responses_surfer.sh on $FOLDER_PATH"
            bash ./process_responses_surfer.sh "$FOLDER_PATH"
        fi
    done < /tmp/new_items.txt
else
    echo "No changes detected."
fi

# Update the previous list file
mv -f "$CURRENT_LIST" "$PREVIOUS_LIST"

# sync results to remote
echo "Copying $LOCAL_DIR to $REMOTE_RESULTS_DIR"
rclone copy "$LOCAL_DIR" "$REMOTE_RESULTS_DIR" \
    --filter "+ *.sbin" \
    --filter "+ */surfer.log" \
    --filter "+ */stitch.log" \
    --filter "+ */charles.log" \
    --filter "+ *.png" \
    --filter "+ *slurm-*" \
    --filter "- *" \
    --skip-links \
    --stats-one-line