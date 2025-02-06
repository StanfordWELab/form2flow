#!/bin/bash

# Function to extract base name without numbering
get_base_name() {
    local filename="$1"
    # First remove .png extension, then consolidate everything after first period
    echo "$filename" | sed 's/\.png$//' | sed -E 's/(\.[0-9.]+)+$//'
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

        # Count number of jobs and calculate array size
        num_jobs=$(wc -l < "$output_file")
        array_size=$(( (num_jobs-1)/8 ))  # Integer division to get number of full groups of 8
        
        # Calculate cores needed for this batch (max 10 per array task)
        cores_needed=$(( num_jobs < 8 ? num_jobs : 8 ))
        # cores_needed=$((cores_needed * 4))
        mem_needed=$((cores_needed * 8))
        
        # Calculate time needed (5 min per array task)
        minutes_needed=$(( array_size * 10 + 10 ))  # Add 5 minutes buffer
        
        # Create VIDEOS directory if it doesn't exist
        mkdir -p "${dir_path}/VIDEOS"
        
        # Submit array job
        cd "$dir_path"
        echo "Submitting array job for $num_jobs videos on $cores_needed cores for $minutes_needed min"
        sbatch --array=0-${num_jobs}:8 -N 1 -n ${cores_needed} --mem=${mem_needed}GB -t ${minutes_needed}:00 ../../../../create_videos.slurm
        cd -
    else
        echo "Warning: No IMAGES folder found in $dir_path"
    fi
    rm "$tmp_file"
done

if [ $? -eq 0 ]; then
    echo "Search completed and all array jobs submitted."
else
    echo "Error during search."
fi 