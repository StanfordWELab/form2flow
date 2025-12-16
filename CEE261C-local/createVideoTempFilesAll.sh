#!/usr/bin/env bash

# Root directory to search (default: current directory)
ROOT="${1:-.}"

# Find directories whose parent matches Final/submission-*
find "$ROOT" -type d | while read -r dir; do
    parent=$(dirname "$dir")

    if [[ $(basename "$parent") == "Final" ]] && \
       [[ $(basename "$dir") == submission-?? ]]; then
        # Create the file inside the directory
        touch "$dir/createVideos2.tmp"
        echo "Created: $dir/createVideos2.tmp"
        # exit
    fi
done