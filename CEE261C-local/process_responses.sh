#!/bin/bash

# Base directory where files are located
FOLDER_PATH="$1"

# Directory containing the template files
TEMPLATE_DIR="./template_files/"

# Define the template file paths
CHARLES_TEMPLATE_FILE="$TEMPLATE_DIR/charles_template.in"
STITCH_TEMPLATE_FILE="$TEMPLATE_DIR/stitch_template.in"
JOB_TEMPLATE_FILE="$TEMPLATE_DIR/job_template.sh"
SURFER_SBIN="./surfer_output.sbin"

# Path to the responses.txt file
RESPONSE_FILE="$FOLDER_PATH/responses.txt"

# Extract input parameters from responses.txt
MESH_REFINEMENT=$(grep -i "Mesh refinement:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
TERRAIN_CATEGORY=$(grep -i "Terrain inflow category:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
SUID=$(grep -i "SUID:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')

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

# Get Domain Size
# Run the command and capture output
module purge
module load system
module load libpng/1.2.57
module load openmpi/4.1.2
output=$(/home/groups/gorle/cascade-inflow/bin/surfer.exe --SURF SBIN "$FOLDER_PATH/$SURFER_SBIN" --BBOX | grep "bounding box dimensions")

# Extract dx, dy, and dz using awk
dx=$(echo "$output" | awk '{for (i=1; i<=NF; i++) if ($i == "dx:") print $(i+1)}')
dy=$(echo "$output" | awk '{for (i=1; i<=NF; i++) if ($i == "dy:") print $(i+1)}')
dz=$(echo "$output" | awk '{for (i=1; i<=NF; i++) if ($i == "dz:") print $(i+1)}')

echo "Extracted values: dx=$dx, dy=$dy, dz=$dz"

# Divide by MESH_SIZE and convert to integers
Y_mesh=$(echo "$dy / $MESH_SIZE" | bc)
Z_mesh=$(echo "$dz / $MESH_SIZE" | bc)

# Convert to integer (floor)
Y_mesh_int=$(printf "%.0f" "$Y_mesh")
Z_mesh_int=$(printf "%.0f" "$Z_mesh")

# Define minimum values
MIN_DY=3
MIN_DZ=3

# Ensure dx and dz are not less than the minimum values
if (( $(echo "$Y_mesh_int < $MIN_DY" | bc -l) )); then
    Y_mesh_int=$MIN_DY
fi

if (( $(echo "$Z_mesh_int < $MIN_DZ" | bc -l) )); then
    Z_mesh_int=$MIN_DZ
fi

# Print results
echo "Y distance in mesh units: $Y_mesh_int"
echo "Z distance in mesh units: $Z_mesh_int"

# Replace placeholders in templates
CHARLES_FILE=$(sed -e "s/{TERRAIN_CATEGORY}/$TERRAIN_VALUE/" \
                   -e "s/{NJ}/$Y_mesh_int/" \
                   -e "s/{NK}/$Z_mesh_int/" "$CHARLES_TEMPLATE_FILE")
STITCH_FILE=$(sed "s/{MESH_SIZE}/$MESH_SIZE/" "$STITCH_TEMPLATE_FILE")
JOB_TEMPLATE_FILE=$(sed "s/{SUID}/$SUID/" "$JOB_TEMPLATE_FILE")

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
sbatch job_template.sh

echo "Job submitted!"
