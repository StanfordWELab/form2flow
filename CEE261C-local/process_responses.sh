#!/bin/bash

# Base directory where files are located
FOLDER_PATH="$1"

# Directory containing the template files
TEMPLATE_DIR="./template_files/"

# Define the template file paths
CHARLES_TEMPLATE_FILE="$TEMPLATE_DIR/charles_template.in"
STITCH_TEMPLATE_FILE="$TEMPLATE_DIR/stitch_template.in"
JOB_TEMPLATE_FILE="$TEMPLATE_DIR/job_template.sh"

# Path to the responses.txt file
RESPONSE_FILE="$FOLDER_PATH/responses.txt"

# Extract input parameters from responses.txt
MESH_REFINEMENT=$(grep -i "Mesh refinement:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
TERRAIN_CATEGORY=$(grep -i "Terrain inflow category:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
SUID=$(grep -i "SUID:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Z_PLANES=$(grep -i "Post-processing z-plane heights:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')

# Convert Z_PLANES string into an array, trimming spaces from each element
IFS=',' read -ra Z_PLANES_ARRAY <<< "$Z_PLANES"
for i in "${!Z_PLANES_ARRAY[@]}"; do
    Z_PLANES_ARRAY[$i]=$(echo "${Z_PLANES_ARRAY[$i]}" | xargs) # trim spaces
done

# Process the terrain category
case "$TERRAIN_CATEGORY" in
    "Category 1") TERRAIN_VALUE="0.01" ;;
    "Category 2") TERRAIN_VALUE="0.05" ;;
    "Category 3") TERRAIN_VALUE="0.3" ;;
    "Category 4") TERRAIN_VALUE="1.0" ;;
    *) echo "Invalid terrain category: $TERRAIN_CATEGORY"; exit 1 ;;
esac

# Process the mesh refinement
case "$MESH_REFINEMENT" in
    "Coarse") MESH_SIZE="1.2" ;;
    "Fine") MESH_SIZE="0.08" ;;
    "Finer") MESH_SIZE="0.04" ;;
    *) echo "Invalid mesh refinement: $MESH_REFINEMENT"; exit 1 ;;
esac


# Replace placeholders in templates
CHARLES_FILE=$(sed -e "s/{TERRAIN_CATEGORY}/$TERRAIN_VALUE/" "$CHARLES_TEMPLATE_FILE")
STITCH_FILE=$(sed "s/{MESH_SIZE}/$MESH_SIZE/" "$STITCH_TEMPLATE_FILE")
JOB_TEMPLATE_FILE=$(sed "s/{SUID}/$SUID/" "$JOB_TEMPLATE_FILE")

# Generate WRITE_IMAGE commands for each z-plane height
WRITE_IMAGE_COMMANDS=""
for Z_HEIGHT in "${Z_PLANES_ARRAY[@]}"; do
    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
WRITE_IMAGE NAME= ./IMAGES/TOP_AVG_UMAG_${Z_HEIGHT} INTERVAL=5000 TARGET 0 0 0.6 CAMERA 0 0 10 UP 0 1 0 SIZE 1920 970 WIDTH 3.2 GEOM PLANE -1 0 ${Z_HEIGHT} 0 0 1 VAR avg(mag(u)) RANGE 0 15.3 COLORMAP GRAYSCALE_RGB"
done

# Debugging output: Check what WRITE_IMAGE_COMMANDS looks like.
# DELETE LATER
echo "WRITE_IMAGE_COMMANDS to be inserted:"
echo "$WRITE_IMAGE_COMMANDS"

# Escape special characters in WRITE_IMAGE_COMMANDS for use in sed
ESCAPED_WRITE_IMAGE_COMMANDS=$(echo "$WRITE_IMAGE_COMMANDS" | sed 's/[&\\]/\\&/g')

# Append the WRITE_IMAGE commands to the end of the CHARLES file
CHARLES_FILE="$CHARLES_FILE
$ESCAPED_WRITE_IMAGE_COMMANDS"


# Write the generated files to the folder
CHARLES_FILE_PATH="$FOLDER_PATH/charles_file.in"
STITCH_FILE_PATH="$FOLDER_PATH/stitch_file.in"
JOB_TEMPLAT_PATH="$FOLDER_PATH/job_template.sh"

echo "$CHARLES_FILE" > "$CHARLES_FILE_PATH"
echo "$STITCH_FILE" > "$STITCH_FILE_PATH"
echo "$JOB_TEMPLATE_FILE" > "$JOB_TEMPLAT_PATH"

# Copy the inflow files
cp -r "$TEMPLATE_DIR/inflow_files" "$FOLDER_PATH"

# Copy the job_template.sh file
cp "$TEMPLATE_DIR/inflow_files" "$FOLDER_PATH"

# Print the details of the operation
echo "Processing new folder: $FOLDER_PATH"
echo "Input parameters:"
echo "  Mesh Refinement: $MESH_REFINEMENT"
echo "  Terrain Inflow Category: $TERRAIN_CATEGORY"
echo "Created charles_file.in, stitch_file.in, copied inflow files, and job_template.sh to $FOLDER_PATH"

# Change directory to the submission folder and submit the job
cd "$FOLDER_PATH"
# Uncoment this to submit jobs
sbatch job_template.sh

echo "Job submitted!"
