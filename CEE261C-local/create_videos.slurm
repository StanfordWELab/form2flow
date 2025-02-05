#!/bin/bash
#SBATCH --job-name=video
#SBATCH --partition=serc
#SBATCH --output=VIDEOS/create_video_%j.out
#SBATCH --time=00:05:00
#SBATCH --mem=4G

image_base="$1"

# Check if IMAGES directory exists and contains matching files
if [ ! -d "./IMAGES" ]; then
    echo "Error: IMAGES directory not found"
    exit 1
fi

# Check if matching image files exist
if [ -z "$(ls ./IMAGES/${image_base}*.png 2>/dev/null)" ]; then
    echo "Error: No matching image files found for pattern: ./IMAGES/${image_base}*.png"
    exit 1
fi

export PATH="/home/groups/gorle/codes/fidelityCharles_2024.1/fidelityCharles_2024.2_CTI/scripts:$PATH"

echo "Creating video for: $image_base"

# Create VIDEOS directory if it doesn't exist
mkdir -p "./VIDEOS"

pwd
# Run lesCreateMovie
lesCreateMovie \
  -infile "./IMAGES/${image_base}*.png" \
  -movie_filename "./VIDEOS/${image_base}" \
  -fps 6 \
  -colormap plasma \
  -colormap_iso seismic \
  -cbar_orient vertical \
  -cbar_width_frac 0.02 \
  -cbar_height_frac 0.45 \
  -fontsize 14
