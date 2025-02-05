ps aux | grep "[r]clone_monitor_runner.sh"
nohup ./rclone_monitor_runner.sh &

To kill
* add rclone_monitor.kill in ./runner_outputs
* ssh to node listed on rclone_monitor.pid and use `kill -9 <PID>`

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

