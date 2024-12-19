#!/bin/bash

MOUNTPOINT_DIR=/home/iaccarino/markben/form2flow/mountpoint
LOCAL_MOUNTPOINT_DIR=/home/iaccarino/markben/form2flow/local-mountpoint
# HARDCODED
ASSIGNMENT_FILES_DIR=/home/iaccarino/markben/form2flow/assignment-starters/assignment-d
# HARDCODED
SCRIPTS_DIR=/home/iaccarino/markben/form2flow/drivers/assignment-d
# HARDCODED
ASSIGNMENT=d

# find all submission directories in the mountpoint
find "$MOUNTPOINT_DIR" -type d -name "submission-*" | while read SUBMISSION_DIR; do

    # Part I: setting up the submission files locally (SAME FOR ALL ASSIGNMENTS)

    # extract student ID and submission number from the path
    STUDENT_ID=$(echo "$SUBMISSION_DIR" | awk -F '/' '{print $(NF-2)}')
    SUBMISSION_NO=$(echo "$SUBMISSION_DIR" | awk -F '/' '{print $NF}')

    # create a unique record file name
    RECORD_FILE="$SCRIPTS_DIR/${STUDENT_ID}-${SUBMISSION_NO}"
    # check if this submission has already been processed
    if [ -f "$RECORD_FILE" ]; then
        continue
    fi

    # mark submission as processed by creating the record file
    touch "$RECORD_FILE"

    # create the destination path in the local mountpoint, mirroring the submission structure
    LOCAL_SUBMISSION_DIR="$LOCAL_MOUNTPOINT_DIR/$STUDENT_ID/$ASSIGNMENT/$SUBMISSION_NO"
    mkdir -p "$LOCAL_SUBMISSION_DIR"

    # copy submission files to the local mountpoint
    cp -r "$SUBMISSION_DIR"/* "$LOCAL_SUBMISSION_DIR/"

    # check for responses.txt, with a 10-second retry if not found
    RESPONSE_FILE="$LOCAL_SUBMISSION_DIR/responses.txt"
    if [ ! -f "$RESPONSE_FILE" ]; then
        echo "Waiting for responses.txt to appear..."
        sleep 10
        if [ ! -f "$RESPONSE_FILE" ]; then
            echo "ERROR: responses.txt not found in $SUBMISSION_DIR"
            continue
        fi
    fi

    # Part II: processing the assignment inputs (MODIFY THIS FOR EACH ASSIGNMENT)

    # read the content of responses.txt and perform actions based on the value
    RESPONSE=$(cat "$RESPONSE_FILE")
    if [ "$RESPONSE" == "Low" ]; then
        cp "$ASSIGNMENT_FILES_DIR/low.txt" "$SUBMISSION_DIR/"
    elif [ "$RESPONSE" == "Medium" ]; then
        cp "$ASSIGNMENT_FILES_DIR/medium.txt" "$SUBMISSION_DIR/"
    elif [ "$RESPONSE" == "High" ]; then
        cp "$ASSIGNMENT_FILES_DIR/high.txt" "$SUBMISSION_DIR/"
    else
        echo "ERROR: Unexpected response value in $RESPONSE_FILE"
    fi

done
