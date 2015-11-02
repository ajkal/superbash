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
 -i input/nvt.in \
 -o EQUILIBRATION/$_name_.nvt.out \
 -c EQUILIBRATION/$_name_.min.crd.6 \
 -r EQUILIBRATION/$_name_.nvt.crd \
 -x EQUILIBRATION/$_name_.nvt.traj \
 -ref EQUILIBRATION/$_name_.min.crd.6

