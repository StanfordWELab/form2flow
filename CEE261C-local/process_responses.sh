#!/bin/bash
source /home/groups/gorle/codes/miniconda3/etc/profile.d/conda.sh
conda activate form2flow

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

# Define the template file paths for urban case files
CHARLES_URBAN_TEMPLATE_FILE="$TEMPLATE_DIR/charles_urbanEnv_template.in"
STITCH_URBAN_TEMPLATE_FILE="$TEMPLATE_DIR/stitch_urbanEnv_template.in"

# Path to the responses.txt file
RESPONSE_FILE="$FOLDER_PATH/responses.txt"

# Extract input parameters from responses.txt
SUID=$(grep -i "SUID:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
SIMULATION_TYPE=$(grep -i "Simulation Type:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
SURFER_NUMBER=$(grep -i "Surfer Number:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r') 
TARGET_BUILDING_HEIGHT=$(grep -i "Target Building Height (m):" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
GRID_RESOLUTION=$(grep -i "Grid Resolution:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
TERRAIN_CATEGORY=$(grep -i "Terrain Category:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Z_PLANES=$(grep -i "Post-processing z-plane heights:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Y_PLANES=$(grep -i "Post-processing y-plane distances:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')

SURFER_NUMBER=$(printf "%02d" "$SURFER_NUMBER")
SURFER_FOLDER="$FOLDER_PATH/../submission_surfer-$SURFER_NUMBER"
SURFER_RESPONSE_FILE="$SURFER_FOLDER/responses_surfer.txt"
cp -n "$SURFER_FOLDER/plane_definitions_rotated.json" "$FOLDER_PATH/"
cp -n "$SURFER_FOLDER/site_rotated.stl" "$FOLDER_PATH/"
cp -n "$SURFER_FOLDER/building_rotated.stl" "$FOLDER_PATH/"
cp -n "$SURFER_RESPONSE_FILE" "$FOLDER_PATH/"

# Check if the responses_surfer.txt file exists
if [ ! -f "$SURFER_RESPONSE_FILE" ]; then
    echo "Error: responses_surfer.txt not found in $FOLDER_PATH"
    exit 1
fi

# Parse domain dimensions (X0, X1)
X0=$(grep -i "X0:" "$SURFER_RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
X1=$(grep -i "X1:" "$SURFER_RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')

X_SPONGE=$(echo "$X1 - 20" | bc)
X_P_SPONGE=$(echo "$X0 + 150" | bc)

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
    "Category 1"*) TERRAIN_VALUE="0.01" ;;
    "Category 2"*) TERRAIN_VALUE="0.05" ;;
    "Category 3"*) TERRAIN_VALUE="0.3" ;;
    "Category 4"*) TERRAIN_VALUE="1.0" ;;
    *) echo "Invalid terrain category: $TERRAIN_CATEGORY"; exit 1 ;;
esac

# Process the grid resolution
case "$GRID_RESOLUTION" in
    "Coarser"*) MESH_SIZE="12" ;;
    "Coarse"*) MESH_SIZE="8" ;;
    "Base"*) MESH_SIZE="6" ;;
    "Fine"*) MESH_SIZE="5" ;;
    *) echo "Invalid grid resolution: $GRID_RESOLUTION"; exit 1 ;;
esac

# Extract domain size from surfer output
module purge
module load system
module load libpng/1.2.57
module load openmpi/4.1.2


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

if (( $(echo "$Y_mesh_int < $MIN_DY" | bc -l) )); then Y_mesh_int=$MIN_DY; fi
if (( $(echo "$Z_mesh_int < $MIN_DZ" | bc -l) )); then Z_mesh_int=$MIN_DZ; fi

# Print results
echo "Y distance in mesh units: $Y_mesh_int"
echo "Z distance in mesh units: $Z_mesh_int"

JOB_FILE=$(sed "s/{SUID}/$SUID/" "$JOB_TEMPLATE_FILE")

# Template selection based on Simulation Type
if [[ "$SIMULATION_TYPE" == "Empty domain" ]]; then
    cp -n "$SURFER_FOLDER/surfer_emptyDomain.sbin" "$FOLDER_PATH/$SURFER_SBIN"
    DOUBLE_BUILDING_HEIGHT=$(echo "$TARGET_BUILDING_HEIGHT * 2" | bc)
    CHARLES_FILE=$(sed -e "s/{TERRAIN_CATEGORY}/$TERRAIN_VALUE/" \
                        -e "s/{NJ}/$Y_mesh_int/" \
                        -e "s/{NK}/$Z_mesh_int/" \
                        -e "s/{BUILDING_HEIGHT}/$TARGET_BUILDING_HEIGHT/" \
                        -e "s/{DOUBLE_BUILDING_HEIGHT}/$DOUBLE_BUILDING_HEIGHT/" \
                        -e "s/{X_SPONGE}/$X_SPONGE/" \
                        -e "s/{X_P_SPONGE}/$X_P_SPONGE/" "$CHARLES_EMPTYDOMAIN_TEMPLATE_FILE")
    STITCH_FILE=$(sed "s/{MESH_SIZE}/$MESH_SIZE/" "$STITCH_EMPTYDOMAIN_TEMPLATE_FILE")
    
    JOB_FILE="$JOB_FILE
/home/groups/gorle/codes/miniconda3/envs/form2flow/bin/python ../../../../post_python.py"

elif [[ "$SIMULATION_TYPE" == "Building in an urban environment" ]]; then
    cp -n "$SURFER_FOLDER/surfer_urbanEnv.sbin" "$FOLDER_PATH/$SURFER_SBIN"
    CHARLES_FILE=$(sed -e "s/{TERRAIN_CATEGORY}/$TERRAIN_VALUE/" \
                    -e "s/{NJ}/$Y_mesh_int/" \
                    -e "s/{NK}/$Z_mesh_int/" \
                    -e "s/{X_SPONGE}/$X_SPONGE/" \
                    -e "s/{X_P_SPONGE}/$X_P_SPONGE/" "$CHARLES_URBAN_TEMPLATE_FILE")
                    
    STITCH_FILE=$(sed "s/{MESH_SIZE}/$MESH_SIZE/" "$STITCH_URBAN_TEMPLATE_FILE")

else
    cp -n "$SURFER_FOLDER/surfer_isolatedBuilding.sbin" "$FOLDER_PATH/$SURFER_SBIN"
    CHARLES_FILE=$(sed -e "s/{TERRAIN_CATEGORY}/$TERRAIN_VALUE/" \
                    -e "s/{NJ}/$Y_mesh_int/" \
                    -e "s/{NK}/$Z_mesh_int/" \
                    -e "s/{X_SPONGE}/$X_SPONGE/" \
                    -e "s/{X_P_SPONGE}/$X_P_SPONGE/" "$CHARLES_TEMPLATE_FILE")

    STITCH_FILE=$(sed "s/{MESH_SIZE}/$MESH_SIZE/" "$STITCH_TEMPLATE_FILE")
fi

# Generate WRITE_IMAGE commands for each z-plane height
WRITE_IMAGE_COMMANDS=""
for Z_HEIGHT in "${Z_PLANES_ARRAY[@]}"; do
    Z_CAMERA_POS=$(echo "$Z_HEIGHT + 100" | bc)
    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
WRITE_IMAGE NAME= ./IMAGES/TOP_AVG_UMAG_Z_${Z_HEIGHT} INTERVAL=10000 TARGET 0 0 ${Z_HEIGHT} CAMERA 0 0 ${Z_CAMERA_POS} UP 0 1 0 SIZE 1920 970 WIDTH 408 GEOM PLANE 0 0 ${Z_HEIGHT} 0 0 1 VAR avg(mag(u)) RANGE 0 15.3 COLORMAP GRAYSCALE_RGB"
done

for Z_HEIGHT in "${Z_PLANES_ARRAY[@]}"; do
    Z_CAMERA_POS=$(echo "$Z_HEIGHT + 100" | bc)
    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
WRITE_IMAGE NAME= ./IMAGES/TOP_STD_UMAG_Z_${Z_HEIGHT} INTERVAL=10000 TARGET 0 0 ${Z_HEIGHT} CAMERA 0 0 ${Z_CAMERA_POS} UP 0 1 0 SIZE 1920 970 WIDTH 408 GEOM PLANE 0 0 ${Z_HEIGHT} 0 0 1 VAR rms(mag(u)) RANGE 0 6 COLORMAP GRAYSCALE_RGB"
done

# Add WRITE_IMAGE command only for the first Z_HEIGHT
if [ ${#Z_PLANES_ARRAY[@]} -gt 0 ]; then
    FIRST_Z_HEIGHT=${Z_PLANES_ARRAY[0]}
    Z_CAMERA_POS=$(echo "$FIRST_Z_HEIGHT + 100" | bc)
    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
WRITE_IMAGE NAME= ./IMAGES/TOP_VID_UMAG_Z_${FIRST_Z_HEIGHT} INTERVAL=20 TARGET 0 0 ${FIRST_Z_HEIGHT} CAMERA 0 0 ${Z_CAMERA_POS} UP 0 1 0 SIZE 1920 970 WIDTH 408 GEOM PLANE 0 0 ${FIRST_Z_HEIGHT} 0 0 1 VAR mag(u) RANGE 0 24 COLORMAP GRAYSCALE_RGB"
fi

# Generate WRITE_IMAGE commands for each y-plane distance
for Y_DISTANCE in "${Y_PLANES_ARRAY[@]}"; do
    Y_CAMERA_POS=$(echo "$Y_DISTANCE - 0.1" | bc)
    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
WRITE_IMAGE NAME= ./IMAGES/SIDE_AVG_UMAG_Y_${Y_DISTANCE} INTERVAL=10000 TARGET 0 ${Y_DISTANCE} 50 CAMERA 0 ${Y_CAMERA_POS} 50 UP 0 0 1 SIZE 1512 860 WIDTH 300 GEOM PLANE 0 ${Y_DISTANCE} 0 0 1 0 VAR avg(mag(u)) RANGE 0 15.3 COLORMAP GRAYSCALE_RGB HIDE_ZONES_NAMED Y0"
done

for Y_DISTANCE in "${Y_PLANES_ARRAY[@]}"; do
    Y_CAMERA_POS=$(echo "$Y_DISTANCE - 0.1" | bc)        
    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
WRITE_IMAGE NAME= ./IMAGES/SIDE_STD_UMAG_Y_${Y_DISTANCE} INTERVAL=10000 TARGET 0 ${Y_DISTANCE} 50 CAMERA 0 ${Y_CAMERA_POS} 50 UP 0 0 1 SIZE 1512 860 WIDTH 300 GEOM PLANE 0 ${Y_DISTANCE} 0 0 1 0 VAR rms(mag(u)) RANGE 0 6 COLORMAP GRAYSCALE_RGB HIDE_ZONES_NAMED Y0"
done

# Add WRITE_IMAGE command only for the first Y_DISTANCE
if [ ${#Y_PLANES_ARRAY[@]} -gt 0 ]; then
    FIRST_Y_DISTANCE=${Y_PLANES_ARRAY[0]}
    Y_CAMERA_POS=$(echo "$FIRST_Y_DISTANCE - 0.1" | bc)
    WRITE_IMAGE_COMMANDS="$WRITE_IMAGE_COMMANDS
WRITE_IMAGE NAME= ./IMAGES/SIDE_VID_UMAG_Y_${FIRST_Y_DISTANCE} INTERVAL=20 TARGET 0 ${FIRST_Y_DISTANCE} 50 CAMERA 0 ${Y_CAMERA_POS} 50 UP 0 0 1 SIZE 1512 860 WIDTH 300 GEOM PLANE 0 ${FIRST_Y_DISTANCE} 0 0 1 0 VAR mag(u) RANGE 0 24 COLORMAP GRAYSCALE_RGB HIDE_ZONES_NAMED Y0"
fi

# Escape special characters in WRITE_IMAGE_COMMANDS for use in sed
ESCAPED_WRITE_IMAGE_COMMANDS=$(echo "$WRITE_IMAGE_COMMANDS" | sed 's/[&\\]/\\&/g')

# Append the WRITE_IMAGE commands to the end of the CHARLES file
CHARLES_FILE="$CHARLES_FILE
$ESCAPED_WRITE_IMAGE_COMMANDS"
    

output=$(/home/groups/gorle/cascade-inflow/bin/surfer.exe --SURF SBIN "$FOLDER_PATH/$SURFER_SBIN" --BBOX | grep "bounding box dimensions")
airflow-generate --input "$FOLDER_PATH/plane_definitions_rotated.json" --output-dir "$FOLDER_PATH/probes_locations"

# --- Append POINTCLOUD_PROBE commands for each ./probes/*.txt ---
if compgen -G "$FOLDER_PATH/probes_locations/*.txt" > /dev/null; then
  for txt in "$FOLDER_PATH"/probes_locations/*.txt; do
    fname=$(basename "$txt" .txt)
    CHARLES_FILE="$CHARLES_FILE
POINTCLOUD_PROBE NAME=probes_results/${fname} INTERVAL=30000 PRECISION=FLOAT GEOM=FILE probes_locations/${fname}.txt VARS = avg(mag(u)) avg(p) comp(avg(u),0) comp(avg(u),1) comp(avg(u),2) comp(rms(u),0) comp(rms(u),1) comp(rms(u),2) rms(p)"
  done
else
  echo "Warning: no probe .txt files found in $FOLDER_PATH/probes_locations/"
fi


JOB_FILE=$(sed "s/{SUID}/$SUID/" "$JOB_TEMPLATE_FILE")

# Write the generated files to the folder
CHARLES_FILE_PATH="$FOLDER_PATH/charles_file.in"
STITCH_FILE_PATH="$FOLDER_PATH/stitch_file.in"
JOB_TEMPLATE_PATH="$FOLDER_PATH/job_template.sh"

if [ ! -f "$CHARLES_FILE_PATH" ]; then
    echo "$CHARLES_FILE" > "$CHARLES_FILE_PATH"
else
    echo "$CHARLES_FILE_PATH already exists. Skipping creation to avoid overwriting."
fi
if [ ! -f "$STITCH_FILE_PATH" ]; then
    echo "$STITCH_FILE" > "$STITCH_FILE_PATH"
else
    echo "$STITCH_FILE_PATH already exists. Skipping creation to avoid overwriting."
fi
if [ ! -f "$JOB_TEMPLATE_PATH" ]; then
    echo "$JOB_FILE" > "$JOB_TEMPLATE_PATH"
else
    echo "$JOB_TEMPLATE_PATH already exists. Skipping creation to avoid overwriting."
fi
# Copy the inflow files
cp -rn "$TEMPLATE_DIR/inflow_files" "$FOLDER_PATH"

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
