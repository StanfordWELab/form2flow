ps aux | grep "[r]clone_monitor_runner.sh"
nohup ./rclone_monitor_runner.sh &
rclone_monitor.kil in runner_outputs kills runner

NOTE: execute ./rclone_monitor_runner.sh from login (not dev) node

Directory Structure: Ensure the following structure inside template_files:
template_files/
├── charles_template.in
├── surfer_template.in
├── stitch_template.in
└── domains_template/
    ├── small/
    │   └── Domain/
    ├── medium/
    │   └── Domain/
    └── large/
        └── Domain/

