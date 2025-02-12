#!/bin/bash

# Function to extract base name without numbering
get_base_name() {
    local filename="$1"
    # First remove .png extension, then consolidate everything after first period
    echo "$filename" | sed 's/\.png$//' | sed -E 's/(\.[0-9.]+)+$//'
}

TRIGGER_FILE=$1
DIR=$2
JOBS_PER_ARRAY=100

echo "Starting search in $DIR directory..."

# Search recursively for createVideo.tmp files in folder and all subdirectories
find $DIR -type f -name "$TRIGGER_FILE" -print | while read -r tmp_file; do
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
        array_size=$(( (num_jobs-1)/JOBS_PER_ARRAY ))  # Integer division to get number of full groups of 8
        
        # Calculate cores needed for this batch (max 10 per array task)
        cores_needed=$(( num_jobs < JOBS_PER_ARRAY ? num_jobs : JOBS_PER_ARRAY ))
        # cores_needed=$((cores_needed * 4))
        mem_needed=$((cores_needed * JOBS_PER_ARRAY))
        
        # Calculate time needed (5 min per array task)
        minutes_needed=$((cores_needed * 15))  # This applies to each job in array
        
        # Create VIDEOS directory if it doesn't exist
        mkdir -p "${dir_path}/VIDEOS"
        
        # Submit array job
        cd "$dir_path"

        #only using 4 cores and 32 GB for now because array not working
        cores_needed=4
        mem_needed=8
        echo "Submitting array job for $num_jobs videos on $cores_needed cores for $minutes_needed min"
        sbatch --array=0-${num_jobs}:${JOBS_PER_ARRAY} -N 1 -n ${cores_needed} --mem=${mem_needed}GB -t ${minutes_needed}:00 ../../../../create_videos.slurm
        cd -
    else
        echo "Warning: No IMAGES folder found in $dir_path"
    fi
    rm "$tmp_file"
    # break # added to slow down videos creation for now
done

if [ $? -eq 0 ]; then
    echo "Search completed and all array jobs submitted."
else
    echo "Error during search."
fi 