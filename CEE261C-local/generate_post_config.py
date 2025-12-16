#!/home/groups/gorle/codes/miniconda3/envs/form2flow/bin/python
import argparse
import json
import os
import glob

def main():
    parser = argparse.ArgumentParser(
        description="Generate JSON configuration with dynamic probe files from --folder"
    )
    parser.add_argument(
        "--folder", required=True,
        help="Base folder containing the configuration files (e.g., /path/to/project)"
    )
    args = parser.parse_args()
    
    # Ensure consistency by removing trailing slash if present
    fldr = args.folder.rstrip("/")
    
    # Construct the base configuration with hardcoded structure
    config = {
        "paths": {
            "base_dir": "./",
            "data_dir": f"{fldr}/data",
            "output_dir": f"{fldr}/output",
            "models": {
                "building": {
                    "path": f"{fldr}/building_rotated.stl",
                    "color": "lightgray",
                    "opacity": 1,
                    "name": "Main Building"
                },
                "site": {
                    "path": f"{fldr}/site_rotated.stl",
                    "color": "lightgray",
                    "opacity": 1,
                    "name": "Buildings"
                }
            }
        },
        "building_volume": 100000.0,
        "building_type": "commercial",
        "planes": {},
        "air_density": 1.225,
        "reference_velocity": 15.3
    }
    
    # Define the probes directory
    probes_dir = os.path.join(fldr, "probes_results")
    
    # Search for all .pcd files in the probes directory
    pxyz_files = glob.glob(os.path.join(probes_dir, "*.pxyz"))
    # Sort the .pxyz files based on their names
    pxyz_files.sort()
    
    # For each .pcd file, extract the plane name and add to the configuration
    for pxyz_file in pxyz_files:
        filename = os.path.basename(pxyz_file)  # e.g., door1.00060000.pcd
        # Use the part before the first period as the key (e.g., "door1")
        name_key = filename.split('.')[0]
        # Construct the .pxyz file path assuming it exists with the same base name
        pcd_files = glob.glob(os.path.join(probes_dir, f"{name_key}.*.pcd"))
        final_step = max([f.split('.')[-2] for f in pcd_files])
        pcd_file = os.path.join(probes_dir, f"{name_key}.{final_step}.pcd")
        # Add an entry to the planes dictionary
        config["planes"][name_key] = {
            "pxyz": pxyz_file,
            "pcd": pcd_file
        }
    
    # Convert the configuration to a formatted JSON string and output it
    json_output = json.dumps(config, indent=4)
    # print(json_output)
    # Save the JSON output to a file in the specified folder
    output_file_path = os.path.join(fldr, "config.json")
    with open(output_file_path, 'w') as json_file:
        json_file.write(json_output)
    print(f"Configuration saved to {output_file_path}")

if __name__ == "__main__":
    main()