#!/bin/bash
#SBATCH --job-name=create_video
#SBATCH --output=create_video_%j.out
#SBATCH --error=create_video_%j.err
#SBATCH --time=00:30:00
#SBATCH --mem=4G

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Required arguments missing"
    echo "Usage: $0 <image_base> <dir_path>"
    exit 1
fi

image_base="$1"
dir_path="$2"

# Check if directory exists
if [ ! -d "${dir_path}" ]; then
    echo "Error: Directory ${dir_path} does not exist"
    exit 1
fi

export PATH="/home/groups/gorle/codes/fidelityCharles_2024.1/fidelityCharles_2024.2_CTI/scripts:$PATH"
cd "${dir_path}"

# Check if IMAGES directory exists and contains matching files
if [ ! -d "./IMAGES" ]; then
    echo "Error: IMAGES directory not found in ${dir_path}"
    exit 1
fi

# Check if matching image files exist
if [ -z "$(ls ./IMAGES/${image_base}*.png 2>/dev/null)" ]; then
    echo "Error: No matching image files found for pattern: ./IMAGES/${image_base}*.png"
    exit 1
fi

echo "Creating video for: $image_base"

# Create temporary config file
cat > "./fidelity.cnf" << EOF
infile = ./IMAGES/${image_base}*.png  # wildcard to match all numbered versions
movie_filename = ./VIDEOS/${image_base}.mp4
fps = 12
colormap = rainbow
colormap_iso = seismic
cbar_orient = vertical
cbar_width_frac = 0.02
cbar_height_frac = 0.45
fontsize = 14
EOF

# Create VIDEOS directory if it doesn't exist
mkdir -p "./VIDEOS"

pwd
# Run lesCreateMovie
lesCreateMovie

# Clean up config file
# rm "./fidelity.cnf"
