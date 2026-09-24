#!/bin/bash
# sysinfo.sh - print basic system information
echo "===== System Information ====="
echo "Hostname : $(hostname)"
echo "Kernel   : $(uname -r)"
echo "OS       : $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo "Uptime   : $(uptime -p)"
echo "CPU      : $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
echo "Cores    : $(nproc)"