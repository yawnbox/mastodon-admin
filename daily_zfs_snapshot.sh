#!/bin/bash

# This script presumes the use of a zfs pool, and Mastodon is installed in /zpool
# 1. 'sudo touch /usr/local/bin/daily_zfs_snapshot.sh' and put this script in here
# 2. 'sudo crontab -e' and add '0 6 * * * /usr/local/bin/daily_zfs_snapshot.sh' for this to run daily at 6AM
# 3. validate logs 'sudo cat /var/log/zfs_snapshot.log'
# Thank you and please share any feedback!

# Name of the ZFS pool
POOL_NAME="zpool"

# Location of log file
LOG_FILE="/var/log/zfs_snapshot.log"

# Get the current date in YYYY_MM_DD_HH_MM_SS format
DATE=$(date +"%Y_%m_%d_%H_%M_%S")

# Identify the latest snapshot and its size
LATEST_SNAPSHOT=$(zfs list -t snapshot -o name -s creation | tail -n 1)

if [[ ! -z "$LATEST_SNAPSHOT" ]]; then
    LATEST_SNAPSHOT_SIZE=$(zfs get -H -o value used "${LATEST_SNAPSHOT}")
else
    LATEST_SNAPSHOT="No previous snapshot"
    LATEST_SNAPSHOT_SIZE="N/A"
fi

# Take a snapshot and measure the time
START_TIME=$(date +%s.%N)
/sbin/zfs snapshot "${POOL_NAME}@${DATE}" || { echo "Snapshot creation failed."; exit 1; }
END_TIME=$(date +%s.%N)
DURATION=$(echo "$END_TIME - $START_TIME" | bc)

# Get used space on the ZFS pool
USED_SPACE=$(/sbin/zfs get -H -o value used "${POOL_NAME}")

# Get available space on the ZFS pool
AVAILABLE_SPACE=$(df -BG /zpool | awk 'NR==2 {print $4}' | sed 's/G//')

# Log the details to the log file
{
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Size of the latest snapshot (${LATEST_SNAPSHOT}): ${LATEST_SNAPSHOT_SIZE}."
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Snapshot ${POOL_NAME}@${DATE} created successfully."
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Duration: ${DURATION} seconds."
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Used space in pool: ${USED_SPACE}."
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Remaining space in pool: ${AVAILABLE_SPACE}G."
} >> $LOG_FILE
