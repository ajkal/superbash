#!/bin/bash

#------------------------------------------------------------------------------

if [ "$SLURM_NTASKS" == 1 ]; then
	SIMULATOR=`which sander`
else
    SIMULATOR="mpirun --mca btl_openib_if_exclude \"mlx4_0:1\" -np $SLURM_NTASKS `which sander.MPI`"
fi
echo "DEBUG: SIMULATOR = $SIMULATOR"

#------------------------------------------------------------------------------

$SIMULATOR -O \
-p build/$_name_.sys_box.prmtop \
-i input/min.in.0 \
-o EQUILIBRATION/$_name_.min.out.0 \
-c build/$_name_.sys_box.inpcrd \
-r EQUILIBRATION/$_name_.min.crd.0 \
-ref build/$_name_.sys_box.inpcrd

$SIMULATOR -O \
-p build/$_name_.sys_box.prmtop \
-i input/min.in.1 \
-o EQUILIBRATION/$_name_.min.out.1 \
-c EQUILIBRATION/$_name_.min.crd.0 \
-r EQUILIBRATION/$_name_.min.crd.1 \
-ref EQUILIBRATION/$_name_.min.crd.0 \
-e EQUILIBRATION/$_name_.min.energy.1 \
-inf EQUILIBRATION/$_name_.min.inf.1

$SIMULATOR -O \
-p build/$_name_.sys_box.prmtop \
-i input/min.in.2 \
-o EQUILIBRATION/$_name_.min.out.2 \
-c EQUILIBRATION/$_name_.min.crd.1 \
-r EQUILIBRATION/$_name_.min.crd.2 \
-ref EQUILIBRATION/$_name_.min.crd.1 \
-e EQUILIBRATION/$_name_.min.energy.2 \
-inf EQUILIBRATION/$_name_.min.inf.2

$SIMULATOR -O \
-p build/$_name_.sys_box.prmtop \
-i input/min.in.3 \
-o EQUILIBRATION/$_name_.min.out.3 \
-c EQUILIBRATION/$_name_.min.crd.2 \
-r EQUILIBRATION/$_name_.min.crd.3 \
-ref EQUILIBRATION/$_name_.min.crd.2 \
-e EQUILIBRATION/$_name_.min.energy.3 \
-inf EQUILIBRATION/$_name_.min.inf.3

$SIMULATOR -O \
-p build/$_name_.sys_box.prmtop \
-i input/min.in.4 \
-o EQUILIBRATION/$_name_.min.out.4 \
-c EQUILIBRATION/$_name_.min.crd.3 \
-r EQUILIBRATION/$_name_.min.crd.4 \
-ref EQUILIBRATION/$_name_.min.crd.3 \
-e EQUILIBRATION/$_name_.min.energy.4 \
-inf EQUILIBRATION/$_name_.min.inf.4

$SIMULATOR -O \
-p build/$_name_.sys_box.prmtop \
-i input/min.in.5 \
-o EQUILIBRATION/$_name_.min.out.5 \
-c EQUILIBRATION/$_name_.min.crd.4 \
-r EQUILIBRATION/$_name_.min.crd.5 \
-ref EQUILIBRATION/$_name_.min.crd.4 \
-e EQUILIBRATION/$_name_.min.energy.5 \
-inf EQUILIBRATION/$_name_.min.inf.5

$SIMULATOR -O \
-p build/$_name_.sys_box.prmtop \
-i input/min.in.6 \
-o EQUILIBRATION/$_name_.min.out.6 \
-c EQUILIBRATION/$_name_.min.crd.5 \
-r EQUILIBRATION/$_name_.min.crd.6 \
-ref EQUILIBRATION/$_name_.min.crd.5 \
-inf EQUILIBRATION/$_name_.min.inf.6

