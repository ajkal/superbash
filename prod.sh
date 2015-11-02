#!/bin/bash

#------------------------------------------------------------------------------
# Load R
module load R
#------------------------------------------------------------------------------
##check if there is any previous production output
## if so, figure out how many output files
cp $_dir_/build/$_name_.sys_box.prmtop $_dir_/PRODUCTION
cp $_dir_/input/dyna.irest.sander $_dir_/PRODUCTION
cp $_dir_/input/dyna.randv.sander $_dir_/PRODUCTION

files=$( ls $_dir_/PRODUCTION/dyna.*.traj.nc | wc -l )
first=$(( $files + 1 ))
last=$(($first + $(( $_iterations_ - 1 )) ))

if [ $first == 1 ]; then
    cp EQUILIBRATION/$_name_.npt.crd PRODUCTION/dyna.00.rst
fi

cd $_dir_/PRODUCTION

~/bin/slurm.jobs.mpi.r --prefix $_name_ \
    --runtime $_walltime_ \
    --cluster "biowulf2" \
    --gpus $_gpus_ \
    --nprocs $_cores_ \
    --start $first \
    --end $last \
    --randv $_randv_ \
    --amd $_amd_
chmod +x submit_${_name_}.sh
./submit_${_name_}.sh
