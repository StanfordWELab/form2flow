# Form2Flow

Form2Flow is a workflow automation pipeline aimed at introductory teaching computational fluid dynamics (CFD) engineering courses. It allows the teaching team to abstract away GUIs or CLIs used to interface with CFD solvers, replacing them with a simple form submission.

It is built using tools in the freely-available [Google Workspace](https://developers.google.com/workspace/). 

The process for running simulations is as simple as filling in a Google Form with geometry files, simulation settings, etc., and receiving the results and logs from the completed simulation in a specified Google Drive folder. The simulations are run on the backend using a CFD solver of your choice, on a HPC system of your choice.

## Setup

Step-by-step instructions for assembling the workflow are provided in [setup_instructions.pdf](https://github.com/benjamark/form2flow/blob/master/setup_instructions.pdf). Some of the details are specific to the implementation used for the ME123 Computational Engineering course taught at Stanford University in the Spring of 2024, but are readily adapted to different solvers, HPC clusters, etc.

The other piece that is useful is the parent directory of the workflow as present on the HPC cluster that runs the simulations, which helps visualize how the different pieces like the mountpoint and drivers fit together. This is provided under the top-level directory of this repository, ```./cluster-files```. Again, some file paths and other minor details are carried over from the ME123 environment.

## Reference

The tool was presented at the American Physical Society's Division of Fluid Dynamics Meeting in November 2024, at a talk titled

[Form to Flow: a cloud-based workflow automation system for introductory CFD courses](https://meetings.aps.org/Meeting/DFD24/Session/L31.8).

The talk was not recorded but the slides are found in this repository: ```aps_form_to_flow.pptx```, which might be a useful reference for the motivation behind his project.

## CEE261C Notes

### Running rclone monitor in background
The command to run the monitor in the background is:
`nohup ./rclone_monitor_runner.sh &`

To check if it is running:
`ps aux | grep rclone_monitor_runner.sh`

To kill:
`kill -9 <ID>`
or create killfile:
`./runner_outputs/rclone_monitor.kill`

### Killing running jobs
The script will copy killfiles from the output folder into the simulation directories. For example, students can kill a charles job by putting a file named `killcharles` (no extension) into the folder with simulation outputs.