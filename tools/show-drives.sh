#!/bin/bash


zpool status | awk '{if($1~/scsi-/){"stat -c=%N /dev/disk/by-id/"$1|getline d;l=split(d,x,">");print $0,x[l];}else{print}}'

