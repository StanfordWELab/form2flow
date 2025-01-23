#!/bin/bash

# Base directory where files are located
FOLDER_PATH="$1"

# Directory containing the template files
TEMPLATE_DIR="/scratch/groups/gorle/CFDClass-local/template_files/"

# Define the template file paths
SURFER_TEMPLATE_FILE="$TEMPLATE_DIR/surfer_template.in"

# Path to the responses_surfer.txt file
RESPONSE_FILE="$FOLDER_PATH/responses_surfer.txt"

# Check if the responses_surfer.txt file exists
if [ ! -f "$RESPONSE_FILE" ]; then
    echo "Error: responses_surfer.txt not found in $FOLDER_PATH"
    exit 1
fi

# Extract input parameters from responses_surfer.txt
WIND_DIRECTION=$(grep -i "Wind direction:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')

# Parse domain dimensions (X0, X1, Y0, Y1, Z0, Z1)
X0=$(grep -i "X0:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
X1=$(grep -i "X1:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Y0=$(grep -i "Y0:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Y1=$(grep -i "Y1:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Z0=$(grep -i "Z0:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
Z1=$(grep -i "Z1:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')

# Print the extracted values for troubleshooting
echo "Extracted values from responses_surfer.txt:"
echo "  WIND_DIRECTION: $WIND_DIRECTION"
echo "  X0: $X0, X1: $X1, Y0: $Y0, Y1: $Y1, Z0: $Z0, Z1: $Z1"

# Replace placeholders in the surfer_template.in file
SURFER_FILE=$(sed -e "s/{WIND_DIRECTION}/$WIND_DIRECTION/" \
                   -e "s/{X_0}/$X0/" \
                   -e "s/{X_1}/$X1/" \
                   -e "s/{Y_0}/$Y0/" \
                   -e "s/{Y_1}/$Y1/" \
                   -e "s/{Z_0}/$Z0/" \
                   -e "s/{Z_1}/$Z1/" "$SURFER_TEMPLATE_FILE")

# Write the generated surfer_file.in to the folder
SURFER_FILE_PATH="$FOLDER_PATH/surfer_file.in"
echo "$SURFER_FILE" > "$SURFER_FILE_PATH"

# Print the details of the operation
echo "Processing new folder: $FOLDER_PATH"
echo "Input parameters:"
echo "  Wind Direction: $WIND_DIRECTION°"
echo "  Domain Dimensions: X0=$X0, X1=$X1, Y0=$Y0, Y1=$Y1, Z0=$Z0, Z1=$Z1"
echo "Created surfer_file.in in $FOLDER_PATH"

# Change directory to the submission folder and submit the job
cd "$FOLDER_PATH"

module purge
module load system
module load libpng/1.2.57
module load openmpi/4.1.2

/home/groups/gorle/cascade-inflow/bin/surfer.exe -i surfer_file.in > surfer.log
