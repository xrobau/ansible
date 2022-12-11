#!/bin/bash

set -x

for x in $(ls -d /sys/class/scsi_host/host*/device/target* | cut -d/ -f5); do echo "- - -" > /sys/class/scsi_host/$x/scan ; done
for i in /sys/class/scsi_device/*/device/rescan ; do echo 1 > $i ; done

