#!/bin/bash

# Function to extract base name without numbering
get_base_name() {
    local filename="$1"
    # Only remove numbers after dots and the .png extension
    echo "$filename" | sed -E 's/\.[0-9]+\./\./' | sed 's/\.png$//'
}

echo "Starting search in SUBS directory..."

# Search recursively for createVideo.tmp files in SUBS folder and all subdirectories
find ./SUBS -type f -name "createVideos.tmp" -print | while read -r tmp_file; do
    echo "Found tmp file: $tmp_file"
    # Get the directory containing the tmp file
    dir_path=$(dirname "$tmp_file")
    
    # Find corresponding IMAGES folder in the same directory
    image_folder="${dir_path}/IMAGES"
    
    if [ -d "$image_folder" ]; then
        # Create output file path
        output_file="${dir_path}/video_images.txt"
        
        echo "Searching for VID images in: $image_folder"
        # Find all images with _VID_ in the name and get unique base names
        find "$image_folder" -type f -name "*_VID_*" | while read -r image; do
            basename=$(basename "$image")
            base_name=$(get_base_name "$basename")
            echo "$base_name"
        done | sort -u > "$output_file"
        
        echo "Created video image list for: $dir_path"
    else
        echo "Warning: No IMAGES folder found in $dir_path"
    fi
done

if [ $? -eq 0 ]; then
    echo "Search completed."
else
    echo "Error during search."
fi 