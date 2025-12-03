#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <job_id_to_exclude>"
    exit 1
fi

EXCLUDE_JOB=$1

# Get all job IDs for the current user
for job in $(squeue -u $USER -h -o "%i"); do
    if [ "$job" -ne "$EXCLUDE_JOB" ]; then
        scancel "$job"
    fi
done

echo "All jobs except Job ID $EXCLUDE_JOB have been canceled."