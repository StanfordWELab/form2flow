#SBATCH --job-name=images-WW
#SBATCH --partition=serc
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --time=2:00:00

# Function to create video for a single image set
create_video() {
    local image_base="$1"
    local dir_path="$2"
    cd "$dir_path"
    
    echo "Creating video for: $image_base"
    
    # Create temporary config file
    cat > "./fidelity.cnf" << EOF
infile = ./IMAGES/${image_base}*
movie_filename = ./VIDEOS/${image_base}
fps = 6
colormap = viridis
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
}

export PATH="/home/groups/gorle/codes/fidelityCharles_2024.1/fidelityCharles_2024.2_CTI/scripts:$PATH"

module purge
module load system
module load libpng/1.2.57
module load openmpi/4.1.2

# Find all video_images.txt files
find ./SUBS -type f -name "video_images.txt" | while read -r txt_file; do
    dir_path=$(dirname "$txt_file")
    echo "Processing directory: $dir_path"
    
    # Read each base image name and create a video
    while read -r image_base; do
        create_video "$image_base" "$dir_path"
    done < "$txt_file"
done 