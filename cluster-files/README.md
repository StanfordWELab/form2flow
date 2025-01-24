```assignment-starters``` The relevant simulation files go here, sorted by assignment. If the cases are live, then this may include input files and job submission scripts. If the cases are pre-run, then the outputs from the simulations are placed here to be copied from.


```drivers``` The bash script to handle the form submission for each assignment goes here. The script is called ```run_me.sh```. The first portion of it contains code that should be the same for all assignments, dealing with ensuring that each submission is handled correctly. The second portion differs depending on the assignment.


```local-mountpoint``` The files from the mountpoint are copied here, the simulations are run (or not, as the case may be), and the file are copied back to the actual mountpoint. See the setup instructions for why.


```mountpoint``` The Rclone mountpoint. Be careful not to perform any operations such as file edits here. This is only a "view" into the Google Drive folder.


```solver``` You can install any solver of your choice here, and call it from the script in the ```drivers``` directory. For pre-run cases, this does not matter.
