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
-i input/equil.in.2 \
-o EQUILIBRATION/$_name_.equil.out.2 \
-c EQUILIBRATION/$_name_.equil.crd.1 \
-r EQUILIBRATION/$_name_.equil.crd.2 \
-x EQUILIBRATION/$_name_.equil.traj.2 \
-ref EQUILIBRATION/$_name_.equil.crd.1

