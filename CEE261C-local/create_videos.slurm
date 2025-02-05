#!/bin/bash
#SBATCH --job-name=video
#SBATCH --partition=serc
#SBATCH --output=VIDEOS/create_video_%A_%a.out
#SBATCH --mem=4G

export PATH="/home/groups/gorle/codes/fidelityCharles_2024.1/fidelityCharles_2024.2_CTI/scripts:$PATH"

# Process videos in parallel within each array task
for i in {0..9}; do
    # Calculate the actual line number to process
    line_num=$((SLURM_ARRAY_TASK_ID+i+1))
    
    # Get the image base name from that line in video_images.txt
    image_base=$(sed -n "${line_num}p" video_images.txt)
    
    # Skip if we've run out of images
    [ -z "$image_base" ] && continue
    
    # Process this image in the background
    echo "Creating video for: $image_base"
    
    # Check if matching image files exist
    if [ -z "$(ls ./IMAGES/${image_base}*.png 2>/dev/null)" ]; then
        echo "Error: No matching image files found for pattern: ./IMAGES/${image_base}*.png"
        exit 1
    fi
    
    # Run lesCreateMovie

    srun --export=ALL -n 1 lesCreateMovie \
        -infile "./IMAGES/${image_base}*.png" \
        -movie_filename "./VIDEOS/${image_base}" \
        -fps 6 \
        -colormap plasma \
        -colormap_iso seismic \
        -cbar_orient vertical \
        -cbar_width_frac 0.02 \
        -cbar_height_frac 0.45 \
        -fontsize 14 &
done

# Wait for all background processes to complete
wait
