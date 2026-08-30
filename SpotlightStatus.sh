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

# Format a byte size in a friendly way, e.g. "1.8 GB", "512 MB".
human_size() {
    local bytes=$1
    awk -v b="$bytes" '
        BEGIN {
            units[0]="B"; units[1]="KB"; units[2]="MB"; units[3]="GB"; units[4]="TB"
            i=0
            size=b
            while (size >= 1024 && i < 4) { size/=1024; i++ }
            printf "%0.1f %s\n", size, units[i]
        }'
}

# Given a path, returns the mounted volume root it belongs to.
volume_root() {
    case "$1" in
        /Volumes/*)
            local vol="${1#/Volumes/}"
            echo "/Volumes/${vol%%/*}"
            ;;
        *)
            echo "/"
            ;;
    esac
}

# Name of the system (root) volume, e.g. "Macintosh HD". Computed once.
SYSVOL=""
system_volume_name() {
    if [ -z "$SYSVOL" ]; then
        SYSVOL=$(diskutil info -plist / 2>/dev/null | awk -F'<string>|</string>' '/<key>VolumeName<\/key>/{getline; print $2}')
    fi
    echo "$SYSVOL"
}

# Loop to continuously show the current file being indexed.
ultimo_archivo=""
while true; do
    # mdworker_shared processes burning the most CPU right now. Force the C
    # locale so %CPU always uses a dot as decimal separator (some locales use a
    # comma, which would break the numeric sort).
    pids=$(LC_ALL=C ps -A -o pid=,pcpu=,comm= \
        | awk '$3 ~ /mdworker_shared/ {print $1}' \
        | head -4)

    # Detect the user file being scanned right now, from the first mdworker
    # that has a real (non-infrastructure) file open.
    archivo=""
    for pid in $pids; do
        a=$(sudo lsof -p "$pid" 2>/dev/null \
            | awk '$4 ~ /r/ && $5=="REG" && $9 ~ /^\//' \
            | grep -vE '/\.Spotlight-V100|/usr/(lib|share)|/System/|dyld$|\.csstore|/dev/' \
            | awk '{sub(/^([^ ]+ +){8}/,""); print}' \
            | tail -1)
        if [ -n "$a" ]; then
            archivo="$a"
            break
        fi
    done

    # Build the current status: either the file, or an activity indicator so
    # the screen never looks silently frozen.
    if [ -n "$archivo" ]; then
        estado="$archivo"
    elif [ -n "$pids" ]; then
        estado="__INDEXING__"
    else
        estado="__IDLE__"
    fi

    # Only do any work (and only print) when the status changed.
    if [ "$estado" != "$ultimo_archivo" ]; then
        ultimo_archivo="$estado"

        if [ "$estado" = "__INDEXING__" ]; then
            echo
            echo "indexing... (no user file capturable right now)"
        elif [ "$estado" = "__IDLE__" ]; then
            echo
            echo "waiting... (no indexing activity right now)"
        else
            archivo="$estado"
            vol=$(volume_root "$archivo")
            if [ "$vol" = "/" ]; then
                vname=$(system_volume_name)
            else
                vname="${vol#/Volumes/}"
            fi

            # Size of the index store on that volume. Only computed when we
            # are going to print. du on the index folder is cheap (~6ms)
            # because it only walks the index metadata.
            # On APFS the system volume's index lives under
            # /System/Volumes/Data/, not directly at the root.
            if [ "$vol" = "/" ]; then
                store="/System/Volumes/Data/.Spotlight-V100"
            else
                store="$vol/.Spotlight-V100"
            fi

            tamanio=""
            if [ -d "$store" ]; then
                # du -sk returns KB (1024-byte blocks) on macOS.
                kb=$(du -sk "$store" 2>/dev/null | awk '{print $1}')
                tamanio=$(human_size $((kb * 1024)))
            else
                tamanio="0 B"
            fi

            # Split path into relative directory and file name.
            dir=$(dirname "$archivo")
            if [ "$vol" = "/" ]; then
                sub="${dir#/}"
            else
                sub="${dir#${vol}/}"
            fi
            base=$(basename "$archivo")

            echo
            echo "[$(date +%H:%M:%S)] Volume: $vname | Index size: $tamanio"
            echo "$sub/"
            echo "$base"
        fi
    fi

    sleep 0.2
done
