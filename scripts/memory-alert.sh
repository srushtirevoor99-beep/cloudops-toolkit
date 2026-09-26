#!/bin/bash
USAGE=$(free|awk '/Mem:/{printf "%.0f" ,$3/$2* 100}')
if [ "$USAGE" -gt 80 ];then
   echo "WARNING:Memory usage is at ${USAGE}%"
else
   echo "Memory usage is fine at ${USAGE}%"
fi
