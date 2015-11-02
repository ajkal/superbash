#!/bin/bash -ue

HOSTNAME=$(hostname -s)

set +ue
source ${MODULESHOME}/init/bash
set -ue
umask 0022

# Load the amber suite
module purge
module load apps/amber/12u21-intel-openmpi
# Specify number of nodes and gpus.

NUM_GPUS_PER_NODE=2
NUM_NODES=$_nodes_
NUM_GPUS=$_gpus_
NUM_PROCS=$_cores_

#------------------------------------------------------------------------------
if [ "$NUM_GPUS" == 1 ]; then
SIMULATOR=pmemd.cuda
else
SIMULATOR=pmemd.cuda.MPI
fi

last=$( ls $_dir_/PRODUCTION/dyna.*.traj.nc | wc -l )
prv=$(printf %02d `expr $last`)

strt=$(echo "1+$last" | bc)
cur=$(printf %02d `expr $strt`)

fin=$(echo "$_iterations_" | bc)
echo running production MD for $strt to $fin iterations

for j in $(seq $strt 1 $fin); do
   $SIMULATOR -O \
   -p build/$_name_.water.top \
   -i input/md.in.2 \
   -o PRODUCTION/dyna.$cur.out \
   -c PRODUCTION/dyna.$prv.rst \
   -r PRODUCTION/dyna.$cur.rst \
   -x PRODUCTION/dyna.$cur.traj.nc \
   -ref PRODUCTION/dyna.$prv.rst
   echo Finished PRODUCTION $cur from $prv at time: `date`
   prv=$cur
   cur=$(printf %02d `expr $cur + 1`)
done
echo finished all `expr $fin - $strt + 1` iterations
