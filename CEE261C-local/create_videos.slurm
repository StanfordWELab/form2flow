#!/bin/bash
#SBATCH --job-name=video
#SBATCH --partition=serc
#SBATCH --output=VIDEOS/create_video_%A_%a.out
#SBATCH --distribution=block:cyclic # Distribute tasks cyclically across available cores
#BATCH --cpus-per-task=1

export PATH="/home/groups/gorle/codes/fidelityCharles_2024.1/fidelityCharles_2024.2_CTI/scripts:$PATH"

JOBS_PER_ARRAY=100

# Calculate the actual line number to process
line_num=$((SLURM_ARRAY_TASK_ID * JOBS_PER_ARRAY + 1))

# Process up to 8 videos per array task
for i in $(seq 0 $((JOBS_PER_ARRAY - 1))); do
    # Calculate current line number
    current_line=$((line_num + i))
    
    # Get the image base name from that line in video_images.txt
    image_base=$(sed -n "${current_line}p" video_images.txt)
    
    # Skip if we've run out of images
    [ -z "$image_base" ] && continue
    
    # Process this image
    echo "Creating video for: $image_base"
    
    # Check if matching image files exist
    if [ -z "$(ls ./IMAGES/${image_base}*.png 2>/dev/null)" ]; then
        echo "Error: No matching image files found for pattern: ./IMAGES/${image_base}*.png"
        continue
    fi
    
    # Run lesCreateMovie
    srun --export=ALL -n 1 --cpus-per-task=1 lesCreateMovie \
        -infile "./IMAGES/${image_base}*.png" \
        -movie_filename "./VIDEOS/${image_base}" \
        -fps 15 \
        -colormap plasma \
        -colormap_iso seismic \
        -cbar_orient vertical \
        -cbar_width_frac 0.02 \
        -cbar_height_frac 0.45 \
        -fontsize 14 &
done

# Wait for all background processes to complete
wait

tar --remove-files -cf IMAGES/video_archive.tar IMAGES/*_VID_*.png
