#!/bin/bash

# Function to create video for a single image set
create_video() {
    local image_base="$1"
    local dir_path="$2"
    
    echo "Creating video for: $image_base"
    
    # Create temporary config file
    cat > "${dir_path}/fidelity.cnf" << EOF
infile = ${dir_path}/IMAGES/${image_base}*.png  # wildcard to match all numbered versions
movie_filename = ${dir_path}/VIDEOS/${image_base}.mp4
fps = 12
colormap = rainbow
colormap_iso = seismic
cbar_orient = vertical
cbar_width_frac = 0.02
cbar_height_frac = 0.45
fontsize = 14
EOF

    # Create VIDEOS directory if it doesn't exist
    mkdir -p "${dir_path}/VIDEOS"
    
    # Run lesCreateMovie
    lesCreateMovie
    
    # Clean up config file
    rm "${dir_path}/fidelity.cnf"
}

# Find all video_images.txt files
find ./SUBS -type f -name "video_images.txt" | while read -r txt_file; do
    dir_path=$(dirname "$txt_file")
    echo "Processing directory: $dir_path"
    
    # Read each base image name and create a video
    while read -r image_base; do
        create_video "$image_base" "$dir_path"
    done < "$txt_file"
done 