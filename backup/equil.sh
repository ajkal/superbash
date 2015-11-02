#!/bin/bash -ue


#------------------------------------------------------------------------------
# Compute how many procs we can run on.  Right now, I'm just doing one
# proc on each node.  But I wonder if we can run lots of procs on
# fewer (or just one) node.  That might be faster than running across
# several nodes.

#NUM_PROCS=$(cat $PBS_NODEFILE | wc -l)
NUM_PROCS=$SLURM_NPROCS

#------------------------------------------------------------------------------
# pmemd.cuda.MPI does not support minimization on multiple GPUs.  So
# we can only use the single-GPU pmemd.cuda.  But that gave me
# cudaFree errors, so now I'm just using plain pmemd.MPI

# NOTE: from the above note, I would have expected SIMULATOR=pmemd.MPI ; however
# in the parent genericMD.sh code we call this script with n=1. So it appears MPI 
# is being avoided. In which case we should not invoke mpiexec... (josepsli)
#------------------------------------------------------------------------------

if [ "$NUM_PROCS" == 1 ]; then
	SIMULATOR=pmemd
else
	SIMULATOR="mpiexec pmemd.MPI"
fi
echo "DEBUG: SIMULATOR = $SIMULATOR"

#------------------------------------------------------------------------------

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/min.in.0 \
-o EQUILIBRATION/$_name_.min.out.0 \
-c build/$_name_.water.crd \
-r EQUILIBRATION/$_name_.min.crd.0 \
-ref build/$_name_.water.crd

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/min.in.1 \
-o EQUILIBRATION/$_name_.min.out.1 \
-c EQUILIBRATION/$_name_.min.crd.0 \
-r EQUILIBRATION/$_name_.min.crd.1 \
-ref EQUILIBRATION/$_name_.min.crd.0 \
-e EQUILIBRATION/$_name_.min.energy.1 \
-inf EQUILIBRATION/$_name_.min.inf.1

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/min.in.2 \
-o EQUILIBRATION/$_name_.min.out.2 \
-c EQUILIBRATION/$_name_.min.crd.1 \
-r EQUILIBRATION/$_name_.min.crd.2 \
-ref EQUILIBRATION/$_name_.min.crd.1 \
-e EQUILIBRATION/$_name_.min.energy.2 \
-inf EQUILIBRATION/$_name_.min.inf.2

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/min.in.3 \
-o EQUILIBRATION/$_name_.min.out.3 \
-c EQUILIBRATION/$_name_.min.crd.2 \
-r EQUILIBRATION/$_name_.min.crd.3 \
-ref EQUILIBRATION/$_name_.min.crd.2 \
-e EQUILIBRATION/$_name_.min.energy.3 \
-inf EQUILIBRATION/$_name_.min.inf.3

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/min.in.4 \
-o EQUILIBRATION/$_name_.min.out.4 \
-c EQUILIBRATION/$_name_.min.crd.3 \
-r EQUILIBRATION/$_name_.min.crd.4 \
-ref EQUILIBRATION/$_name_.min.crd.3 \
-e EQUILIBRATION/$_name_.min.energy.4 \
-inf EQUILIBRATION/$_name_.min.inf.4

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/min.in.5 \
-o EQUILIBRATION/$_name_.min.out.5 \
-c EQUILIBRATION/$_name_.min.crd.4 \
-r EQUILIBRATION/$_name_.min.crd.5 \
-ref EQUILIBRATION/$_name_.min.crd.4 \
-e EQUILIBRATION/$_name_.min.energy.5 \
-inf EQUILIBRATION/$_name_.min.inf.5

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/min.in.6 \
-o EQUILIBRATION/$_name_.min.out.6 \
-c EQUILIBRATION/$_name_.min.crd.5 \
-r EQUILIBRATION/$_name_.min.crd.6 \
-ref EQUILIBRATION/$_name_.min.crd.5 \
-inf EQUILIBRATION/$_name_.min.inf.6

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/equil.in.1 \
-o EQUILIBRATION/$_name_.equil.out.1 \
-c EQUILIBRATION/$_name_.min.crd.6 \
-r EQUILIBRATION/$_name_.equil.crd.1 \
-x EQUILIBRATION/$_name_.equil.traj.1 \
-ref EQUILIBRATION/$_name_.min.crd.6

$SIMULATOR -O \
-p build/$_name_.water.top \
-i input/equil.in.2 \
-o EQUILIBRATION/$_name_.equil.out.2 \
-c EQUILIBRATION/$_name_.equil.crd.1 \
-r EQUILIBRATION/$_name_.equil.crd.2 \
-x EQUILIBRATION/$_name_.equil.traj.2 \
-ref EQUILIBRATION/$_name_.equil.crd.1

