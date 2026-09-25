#!/bin/bash
USAGE=$(df / |awk 'NR==2{print $5}'|tr -d '%')
if [ "$USAGE" -gt 80 ];then
   echo "WARNING:Disk usage is at ${USAGE}%"
else
   echo "Disk usage is fine at ${USAGE}%"
fi
