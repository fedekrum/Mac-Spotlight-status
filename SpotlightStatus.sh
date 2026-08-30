#!/bin/bash

# SpotlightStatus.sh - A simple bash script to see what file Spotlight is indexing.
#
# Sometimes Spotlight indexing status is unclear. It just says "Indexing" and you
# have no idea if there is any progress or what it is stuck on.
#
# Inspired by fedekrum/Mac-Time-Machine-status, this script shows in real time
# which file the indexing process (mdworker_shared) is currently working on, so
# you can tell it is making progress and not stuck.
#
# It must be run as root, so you will be prompted for credentials if you are not.
# No modification is made on any file and no risky commands are run on the script
# as you can check.

# Check if we're root and re-run if not.
if [ $(id -u) -ne 0 ]; then
    echo "Script not running as root, trying to elevate to root..."
    sudo bash "$0" "$@"
    exit $?
fi
clear

# If Spotlight indexing is not running (no mds_stores), there is nothing to watch.
if [ -z "$(pgrep mds_stores)" ]; then
    echo "Spotlight indexing is not running."
    exit 1
fi

# Print the overall status from the official tool.
mdutil -s /

echo
echo "==========================================================="
echo " Following the file Spotlight is indexing right now..."
echo " Press Ctrl+C to stop."
echo "==========================================================="
echo

# Loop to continuously show the current file being indexed.
while true; do
    # Pick the mdworker_shared process burning the most CPU right now.
    pid=$(ps -A -o pid=,pcpu=,comm= | awk '$3 ~ /mdworker_shared/ {print $2, $1}' \
        | sort -rn | head -1 | awk '{print $2}')

    if [ -n "$pid" ]; then
        # Oldest fd open in read mode on a regular file of the user (not the index
        # store, not system libs), that's the file being scanned/indexed.
        archivo=$(sudo lsof -p "$pid" 2>/dev/null \
            | awk '$4 ~ /r/ && $5=="REG" && $NF ~ /^\//' \
            | grep -vE '/\.Spotlight-V100|/usr/(lib|share)|/System/|dyld$|\.csstore|\.DS_Store' \
            | tail -1 | awk '{print $NF}')

        if [ -n "$archivo" ]; then
            echo "[$(date +%H:%M:%S)] $archivo"
        fi
    fi

    sleep 1
done
