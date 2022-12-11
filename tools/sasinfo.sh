#!/bin/bash

ENC=$(echo /sys/class/enclosure/*)
if [ ! "$ENC" ]; then
        print "No enclosures found"
        exit
fi

for e in $ENC; do
        MODEL=$(cat $e/device/model 2>/dev/null)
        if [ ! "$MODEL" ]; then
                echo "Unknown enclosure model $e"
        else
                echo "$(basename $e) is $MODEL"
        fi
        SLOTS=$(cd $e; ls -d [0-9]* | sort -n)
        for s in $SLOTS; do
                echo -n "  Bay $s: "
                if [ ! -e $e/$s/device/model ]; then
                        echo "Empty"
                else
                        MODEL=$(cat $e/$s/device/model)
                        SERIAL=$(strings $e/$s/device/vpd_pg80)
                        echo $MODEL $SERIAL
                fi
        done

done



