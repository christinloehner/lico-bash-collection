#!/bin/bash 
# Written by Alexander Löhner 
# The Linux Counter Project 
# Updated on Sep. 8th 2015 by Mike Hay to remove dependency on 'bc' 
 
if [[ "${1}" = "" ]]; then
        echo "please add the name of the process as a parameter"
        exit 1
fi

for i in $(pidof $1); do echo $(awk '/Private/ {sum+=$2} END {print sum}' /proc/$i/smaps); done | awk '{sum+=$1} END {printf("%.2f\n", sum/1000)}'
