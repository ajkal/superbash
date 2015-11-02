#!/bin/bash -ue

#export MODULESHOME=/gne/research/apps/modules/3.2.6/x86_64-linux-2.6-sles11/Modules/3.2.6/
#source ${MODULESHOME}/init/bash

#------------------------------------------------------------------------------
# Load the amber suite
module load amber/14-gpu

#------------------------------------------------------------------------------
# Compute how many GPU nodes we can run on.
# NOTE: Cannot depend on NUM_GPUS_PER_NODE always remaining consistent.

#NUM_GPUS_PER_NODE=2
#NUM_NODES=$SLURM_JOB_NUM_NODES
#NUM_PROCS=$SLURM_NPROCS
#NUM_GPUS=$NUM_PROCS

#------------------------------------------------------------------------------
# See this page for some information on how to run pmemd with multiple GPUs:
# http://ambermd.org/gpus/

if [ "$NUM_GPUS" == 1 ]; then
SIMULATOR=pmemd.cuda

#------------------------------------------------------------------------------
for i in $(seq $cur 1 $_iterations_);
$SIMULATOR -O \
  -p build/$_name_.water.top \
  -i input/md.in.1 \
  -o PRODUCTION/dyna.$cur.out \
  -c \
  -r PRODUCTION/dyna.$cur.rst \
  -x PRODUCTION/dyna.$cur.traj.nc \
  -ref EQUILIBRATION/$_name_.equil.crd.2
echo Finished PRODUCTION $cur from $prv at time: `date`
prv=$cur
cur=$(printf %02d `expr $cur + 1`)

for i in $(seq 2 1 $_iterations_);
do
   $SIMULATOR -O \
   -p build/$_name_.water.top \
   -i input/md.in.2 \
   -o PRODUCTION/dyna.$cur.out \
   -c PRODUCTION/dyna.$prv.rst \
   -r PRODUCTION/dyna.$cur.rst \
   -x PRODUCTION/dyna.$cur.traj.nc \
   -ref PRODUCTION/dyna.$prv.traj.nc
   echo Finished PRODUCTION $cur from $prv at time: `date`
   prv=$cur
   cur=$(printf %02d `expr $cur + 1`)
done 

else
prv=00
cur=01

SIMULATOR=pmemd.cuda.MPI
mpiexec $SIMULATOR -O \
  -p build/$_name_.water.top \
  -i input/md.in.1 \
  -o PRODUCTION/dyna.$cur.out \
  -c EQUILIBRATION/$_name_.equil.crd.2 \
  -r PRODUCTION/dyna.$cur.rst \
  -x PRODUCTION/dyna.$cur.traj.nc \
  -ref EQUILIBRATION/$_name_.equil.crd.2
prv=$cur
cur=$(printf %02d `expr $cur + 1`)
echo Finished PRODUCTION $cur from $prv at time: `date`

for i in {2..$_iterations_};
do
   mpiexec $SIMULATOR -O \
   -p build/$_name_.water.top \
   -i input/md.in.2 \
   -o PRODUCTION/dyna.$cur.out \
   -c PRODUCTION/dyna.$prv.rst \
   -r PRODUCTION/dyna.$cur.rst \
   -x PRODUCTION/dyna.$cur.traj.nc \
   -ref PRODUCTION/dyna.$prv.rst
   prv=$cur
   cur=$(printf %02d `expr $cur + 1`)
   echo Finished PRODUCTION $cur from $prv at time: `date`
done

fi

#------------------------------------------------------------------------------
# Note the end time

echo $0 'finished at' $( date )
