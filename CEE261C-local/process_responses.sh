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

# Define the template file paths for emptyDomain files
CHARLES_EMPTYDOMAIN_TEMPLATE_FILE="$TEMPLATE_DIR/charles_emptyDomain_template.in"
STITCH_EMPTYDOMAIN_TEMPLATE_FILE="$TEMPLATE_DIR/stitch_emptyDomain_template.in"

# Path to the responses.txt file
RESPONSE_FILE="$FOLDER_PATH/responses.txt"

# Extract input parameters from responses.txt
MESH_REFINEMENT=$(grep -i "Mesh refinement:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
TERRAIN_CATEGORY=$(grep -i "Terrain inflow category:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
SUID=$(grep -i "SUID:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Z_PLANES=$(grep -i "Post-processing z-plane heights:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Y_PLANES=$(grep -i "Post-processing y-plane distances:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
CONSIDER_EMPTY_DOMAIN=$(grep -i "Consider empty domain:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
BUILDING_HEIGHT=$(grep -i "Building height (m):" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')


# Convert Z_PLANES string into an array, trimming spaces from each element
IFS=',' read -ra Z_PLANES_ARRAY <<< "$Z_PLANES"
for i in "${!Z_PLANES_ARRAY[@]}"; do
    Z_PLANES_ARRAY[$i]=$(echo "${Z_PLANES_ARRAY[$i]}" | xargs) # trim spaces
done

# Convert Y_PLANES string into an array, trimming spaces from each element
IFS=',' read -ra Y_PLANES_ARRAY <<< "$Y_PLANES"
for i in "${!Y_PLANES_ARRAY[@]}"; do
    Y_PLANES_ARRAY[$i]=$(echo "${Y_PLANES_ARRAY[$i]}" | xargs) # trim spaces
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
    "Coarse") MESH_SIZE="15" ;;
    "Fine") MESH_SIZE="10" ;;
    "Finer") MESH_SIZE="5" ;;
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

if [[ "$CONSIDER_EMPTY_DOMAIN" == "Yes" ]]; then
    # Double the building height
    DOUBLE_BUILDING_HEIGHT=$(echo "$BUILDING_HEIGHT * 2" | bc)

    # Use the empty domain template file and replace placeholders
    CHARLES_FILE=$(sed -e "s/{TERRAIN_CATEGORY}/$TERRAIN_VALUE/" \
                        -e "s/{NJ}/$Y_mesh_int/" \
                        -e "s/{NK}/$Z_mesh_int/" \
                        -e "s/{BUILDING_HEIGHT}/$BUILDING_HEIGHT/" \
                        -e "s/{DOUBLE_BUILDING_HEIGHT}/$DOUBLE_BUILDING_HEIGHT/" "$CHARLES_EMPTYDOMAIN_TEMPLATE_FILE")


    STITCH_FILE=$(sed "s/{MESH_SIZE}/$MESH_SIZE/" "$STITCH_EMPTYDOMAIN_TEMPLATE_FILE")
else
    # Replace placeholders in templates
    CHARLES_FILE=$(sed -e "s/{TERRAIN_CATEGORY}/$TERRAIN_VALUE/" \
                    -e "s/{NJ}/$Y_mesh_int/" \
                    -e "s/{NK}/$Z_mesh_int/" "$CHARLES_TEMPLATE_FILE")
    STITCH_FILE=$(sed "s/{MESH_SIZE}/$MESH_SIZE/" "$STITCH_TEMPLATE_FILE")

    # Generate WRITE_IMAGE commands for each z-plane height
    WRITE_IMAGE_COMMANDS=""
    for Z_HEIGHT in "${Z_PLANES_ARRAY[@]}"; do
        WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
    WRITE_IMAGE NAME= ./IMAGES/TOP_AVG_UMAG_Z_${Z_HEIGHT} INTERVAL=10000 TARGET 0 0 250 CAMERA 0 0 800 UP 0 1 0 SIZE 1920 970 WIDTH 408 GEOM PLANE 0 0 ${Z_HEIGHT} 0 0 1 VAR avg(mag(u)) RANGE 0 15.3 COLORMAP GRAYSCALE_RGB"
    done

    for Z_HEIGHT in "${Z_PLANES_ARRAY[@]}"; do
        WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
    WRITE_IMAGE NAME= ./IMAGES/TOP_STD_UMAG_Z_${Z_HEIGHT} INTERVAL=10000 TARGET 0 0 250 CAMERA 0 0 800 UP 0 1 0 SIZE 1920 970 WIDTH 408 GEOM PLANE 0 0 ${Z_HEIGHT} 0 0 1 VAR rms(mag(u)) RANGE 0 6 COLORMAP GRAYSCALE_RGB"
    done

    #for Z_HEIGHT in "${Z_PLANES_ARRAY[@]}"; do
    #    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
    #WRITE_IMAGE NAME= ./IMAGES/TOP_VID_UMAG_Z_${Z_HEIGHT} INTERVAL=100 TARGET 0 0 250 CAMERA 0 0 800 UP 0 1 0 SIZE 1920 970 WIDTH 408 GEOM PLANE 0 0 ${Z_HEIGHT} 0 0 1 VAR mag(u) RANGE 0 24 COLORMAP GRAYSCALE_RGB"
    #done

    # Add WRITE_IMAGE command only for the first Z_HEIGHT
    if [ ${#Z_PLANES_ARRAY[@]} -gt 0 ]; then
        FIRST_Z_HEIGHT=${Z_PLANES_ARRAY[0]}
        WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
    WRITE_IMAGE NAME= ./IMAGES/TOP_VID_UMAG_Z_${FIRST_Z_HEIGHT} INTERVAL=20 TARGET 0 0 250 CAMERA 0 0 800 UP 0 1 0 SIZE 1920 970 WIDTH 408 GEOM PLANE 0 0 ${FIRST_Z_HEIGHT} 0 0 1 VAR mag(u) RANGE 0 24 COLORMAP GRAYSCALE_RGB"
    fi

    # Generate WRITE_IMAGE commands for each y-plane distance
    for Y_DISTANCE in "${Y_PLANES_ARRAY[@]}"; do
        WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
    WRITE_IMAGE NAME= ./IMAGES/SIDE_AVG_UMAG_Y_${Y_DISTANCE} INTERVAL=10000 TARGET 0 0 50 CAMERA 0 -559 50 UP 0 0 1 SIZE 1512 860 WIDTH 300 GEOM PLANE 0 ${Y_DISTANCE} 0 0 1 0 VAR avg(mag(u)) RANGE 0 15.3 COLORMAP GRAYSCALE_RGB HIDE_ZONES_NAMED Y0"
    done

    for Y_DISTANCE in "${Y_PLANES_ARRAY[@]}"; do
        WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
    WRITE_IMAGE NAME= ./IMAGES/SIDE_STD_UMAG_Y_${Y_DISTANCE} INTERVAL=10000 TARGET 0 0 50 CAMERA 0 -559 50 UP 0 0 1 SIZE 1512 860 WIDTH 300 GEOM PLANE 0 ${Y_DISTANCE} 0 0 1 0 VAR rms(mag(u)) RANGE 0 6 COLORMAP GRAYSCALE_RGB HIDE_ZONES_NAMED Y0"
    done

    #for Y_DISTANCE in "${Y_PLANES_ARRAY[@]}"; do
    #    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
    #WRITE_IMAGE NAME= ./IMAGES/SIDE_VID_UMAG_Y_${Y_DISTANCE} INTERVAL=100 TARGET 0 0 50 CAMERA 0 -559 50 UP 0 0 1 SIZE 1512 860 WIDTH 300 GEOM PLANE 0 ${Y_DISTANCE} 0 0 1 0 VAR mag(u) RANGE 0 24 COLORMAP GRAYSCALE_RGB HIDE_ZONES_NAMED Y0"
    #done

    # Add WRITE_IMAGE command only for the first Y_DISTANCE
    if [ ${#Y_PLANES_ARRAY[@]} -gt 0 ]; then
        FIRST_Y_DISTANCE=${Y_PLANES_ARRAY[0]}
        WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
    WRITE_IMAGE NAME= ./IMAGES/SIDE_VID_UMAG_Y_${FIRST_Y_DISTANCE} INTERVAL=20 TARGET 0 0 50 CAMERA 0 -559 50 UP 0 0 1 SIZE 1512 860 WIDTH 300 GEOM PLANE 0 ${FIRST_Y_DISTANCE} 0 0 1 0 VAR mag(u) RANGE 0 24 COLORMAP GRAYSCALE_RGB HIDE_ZONES_NAMED Y0"
    fi

    # Debugging output: Check what WRITE_IMAGE_COMMANDS looks like
    # DELETE LATER
    echo "WRITE_IMAGE_COMMANDS to be inserted:"
    echo "$WRITE_IMAGE_COMMANDS"

    # Escape special characters in WRITE_IMAGE_COMMANDS for use in sed
    ESCAPED_WRITE_IMAGE_COMMANDS=$(echo "$WRITE_IMAGE_COMMANDS" | sed 's/[&\\]/\\&/g')

    # Append the WRITE_IMAGE commands to the end of the CHARLES file
    CHARLES_FILE="$CHARLES_FILE
    $ESCAPED_WRITE_IMAGE_COMMANDS"
fi

JOB_FILE=$(sed "s/{SUID}/$SUID/" "$JOB_TEMPLATE_FILE")

# Write the generated files to the folder
CHARLES_FILE_PATH="$FOLDER_PATH/charles_file.in"
STITCH_FILE_PATH="$FOLDER_PATH/stitch_file.in"
JOB_TEMPLATE_PATH="$FOLDER_PATH/job_template.sh"

echo "$CHARLES_FILE" > "$CHARLES_FILE_PATH"
echo "$STITCH_FILE" > "$STITCH_FILE_PATH"
echo "$JOB_FILE" > "$JOB_TEMPLATE_PATH"
# Copy the inflow files
cp -r "$TEMPLATE_DIR/inflow_files" "$FOLDER_PATH"

# Print the details of the operation
echo "Processing new folder: $FOLDER_PATH"
echo "Input parameters:"
echo "  Mesh Refinement: $MESH_REFINEMENT"
echo "  Terrain Inflow Category: $TERRAIN_CATEGORY"
echo "Created charles_file.in, stitch_file.in, copied inflow files, and job_template.sh to $FOLDER_PATH"

# Change directory to the submission folder and submit the job
cd "$FOLDER_PATH"
# Uncomment this to submit jobs
sbatch job_template.sh

echo "Job submitted!"
