#!/bin/bash

echo "=============================="
echo "Time: $(date)"

echo
echo "Load Average:"
awk '{print "LA1="$1" LA5="$2" LA15="$3}' /proc/loadavg

echo
echo "Free disk space:"
df -h / | awk 'NR==2 {print "Available: "$4" ("$5" used)"}'

echo
echo "Top-5 processes by memory:"
ps -eo pid,user,%mem,comm --sort=-%mem | head -n 6

echo "=============================="