#!/bin/bash -ue

#export MODULESHOME=/gne/research/apps/modules/3.2.6/x86_64-linux-2.6-sles11/Modules/3.2.6/
set +ue
#source ${MODULESHOME}/init/bash
. /gne/research/apps/modules/common/bashrc
set -ue
umask 0022

#------------------------------------------------------------------------------
# Load the amber suite
module purge
module load apps/amber/12u21-intel-openmpi

#------------------------------------------------------------------------------
# Compute how many GPU nodes we can run on.
# NOTE: Cannot depend on NUM_GPUS_PER_NODE always remaining consistent.

NUM_GPUS_PER_NODE=2
NUM_NODES=$SLURM_JOB_NUM_NODES
NUM_PROCS=$SLURM_NPROCS
NUM_GPUS=$NUM_PROCS

#------------------------------------------------------------------------------
# See this page for some information on how to run pmemd with multiple GPUs:
# http://ambermd.org/gpus/

if [ "$NUM_GPUS" == 1 ]; then
SIMULATOR=pmemd.cuda

#------------------------------------------------------------------------------

$SIMULATOR -O \
  -p build/$_name_.water.top \
  -i input/md.in.1 \
  -o PRODUCTION/dyna.$cur.out \
  -c EQUILIBRATION/dyna.$prv.rst \
  -r PRODUCTION/dyna.$cur.rst \
  -x PRODUCTION/dyna.$cur.traj.nc \
  -ref EQUILIBRATION/dyna.$cur.rst

prv=00
cur=01

for i in {2..$_iterations_};
do
   $SIMULATOR -O \
   -p build/$_name_.water.top \
   -i input/md.in.2 \
   -o PRODUCTION/dyna.$cur.out \
   -c EQUILIBRATION/dyna.$prv.rst \
   -r PRODUCTION/dyna.$cur.rst \
   -x PRODUCTION/dyna.$cur.traj.nc \
   -ref EQUILIBRATION/dyna.$cur.rst
   prv=$cur
   cur=$(printf %02d `expr $cur + 1`)
done 

else
SIMULATOR=pmemd.cuda.MPI
mpiexec $SIMULATOR -O \
  -p build/$_name_.water.top \
  -i input/md.in.1 \
  -o PRODUCTION/dyna.$cur.out \
  -c EQUILIBRATION/dyna.$prv.rst \
  -r PRODUCTION/dyna.$cur.rst \
  -x PRODUCTION/dyna.$cur.traj.nc \
  -ref EQUILIBRATION/dyna.$cur.rst

prv=00
cur=01

for i in {2..$_iterations_};
do
   mpiexec $SIMULATOR -O \
   -p build/$_name_.water.top \
   -i input/md.in.2 \
   -o PRODUCTION/dyna.$cur.out \
   -c EQUILIBRATION/dyna.$prv.rst \
   -r PRODUCTION/dyna.$cur.rst \
   -x PRODUCTION/dyna.$cur.traj.nc \
   -ref EQUILIBRATION/dyna.$cur.rst
   prv=$cur
   cur=$(printf %02d `expr $cur + 1`)
done

fi

#------------------------------------------------------------------------------
# Note the end time

echo $0 'finished at' $( date )
