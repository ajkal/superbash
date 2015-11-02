#!/bin/bash
echo starting
output=$(sbatch ~/bin/test.sh)
echo done with output     
temp=$(echo $output | cut -f4 -d' ')

