#!/bin/bash

# Base directory passed as an argument
FOLDER_PATH="$1"

# Ensure the folder path exists
if [ ! -d "$FOLDER_PATH" ]; then
    echo "Invalid folder path: $FOLDER_PATH"
    exit 1
fi

# Path to the responses.txt file
RESPONSE_FILE="$FOLDER_PATH/responses.txt"

# Check if the responses.txt file exists
if [ ! -f "$RESPONSE_FILE" ]; then
    echo "responses.txt not found in $FOLDER_PATH, skipping."
    exit 1
fi

# Extract input parameters from responses.txt
WIND_DIRECTION=$(grep -i "Wind direction:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
WIND_SPEED=$(grep -i "Wind speed (m/s):" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')
TERRAIN_CATEGORY=$(grep -i "Terrain inflow category:" "$RESPONSE_FILE" | awk -F': ' '{print $2}' | tr -d '\r')

# Validate input parameters
if [ -z "$WIND_DIRECTION" ] || [ -z "$WIND_SPEED" ] || [ -z "$TERRAIN_CATEGORY" ]; then
    echo "Missing Wind direction, Wind speed, or Terrain category in $RESPONSE_FILE, skipping folder $FOLDER_PATH"
    exit 1
fi

# Process the terrain category
case "$TERRAIN_CATEGORY" in
    "Category 1") TERRAIN_VALUE="0.01" ;;
    "Category 2") TERRAIN_VALUE="0.05" ;;
    "Category 3") TERRAIN_VALUE="0.3" ;;
    "Category 4") TERRAIN_VALUE="1.0" ;;
    *)
        echo "Unknown Terrain inflow category in $RESPONSE_FILE, skipping folder $FOLDER_PATH"
        exit 1
        ;;
esac

# Replace placeholders in charles_template.in
CHARLES_TEMPLATE_FILE="charles_template.in"
CHARLES_FILE=$(sed -e "s/{WIND_SPEED}/$WIND_SPEED/" -e "s/{TERRAIN_CATEGORY}/$TERRAIN_VALUE/" "$CHARLES_TEMPLATE_FILE")

# Replace placeholders in surfer_template.in
SURFER_TEMPLATE_FILE="surfer_template.in"
SURFER_FILE=$(sed "s/{WIND_DIRECTION}/$WIND_DIRECTION/" "$SURFER_TEMPLATE_FILE")

# Write the generated files
CHARLES_FILE_PATH="$FOLDER_PATH/charles_file.in"
SURFER_FILE_PATH="$FOLDER_PATH/surfer_file.in"
echo "$CHARLES_FILE" > "$CHARLES_FILE_PATH"
echo "$SURFER_FILE" > "$SURFER_FILE_PATH"

# Print the details of the operation
echo "Processing new folder: $FOLDER_PATH"
echo "Input parameters:"
echo "  Wind Speed: $WIND_SPEED m/s"
echo "  Wind Direction: $WIND_DIRECTION°"
echo "  Terrain Inflow Category: $TERRAIN_CATEGORY"
echo "Created charles_file.in and surfer_file.in in $FOLDER_PATH"
