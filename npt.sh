#!/bin/bash


#------------------------------------------------------------------------------

[[ $SLURM_NTASKS != $_gpus_ ]] && fail "Can only run one task/gpu!"
if [ $_gpus_ > 1 ]; then
    SIMULATOR="mpirun -np $SLURM_NTASKS `which pmemd.cuda`"
elif [ $_gpus_ == 1 ]; then
    SIMULATOR="mpirun -np 1 `which pmemd`"
else
    echo Number of GPUs is $_gpus_: cannot be less than 1
fi
$echo "DEBUG: SIMULATOR = $SIMULATOR"

#------------------------------------------------------------------------------

 $SIMULATOR -O \
 -p build/$_name_.sys_box.prmtop \
 -i input/npt.in \
 -o EQUILIBRATION/$_name_.npt.out \
 -c EQUILIBRATION/$_name_.nvt.crd \
 -r EQUILIBRATION/$_name_.npt.crd \
 -x EQUILIBRATION/$_name_.npt.traj \
 -ref EQUILIBRATION/$_name_.min.crd.6

