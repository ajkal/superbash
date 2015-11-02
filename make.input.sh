#!/bin/bash

#-----------------------------------------------------------------------------

dir=${1?'Must specify work dir'}
T=${2?'Must specify temperature'}
nstlim=${3?'Must specify nstlim'}
dt=${4?'Must specify dt'}
ntwx=${5?'Must specify ntwx'}
residues=${6?'Must specify number of residues'}
#pressure=${7?'must be pressure or volume'}

# restart production dynamics with SHAKE, write crd every 2 ps for 1ns
##create imin_gb.in input file
cat <<eof > $dir/input/imin.gb.in
minimize structure
 &cntrl
  imin   = 1,
  maxcyc = 100,
  ncyc   = 20,
  ntb    = 0,
  igb    = 1,
  cut    = 12
 /

eof

## create zeroth input files for minization of solvated system
cat <<eof > $dir/input/min.in.0
Initial minimiation of solvent
 &cntrl
        ncyc=100,
        ntr=1,
        ntx=1,
        ntpr=1,
        imin=1,
        maxcyc=100,
        cut=9,
        ntp=1,ntb=2,
        saltcon=0.1,
 / 
Solute is restrained
40.000000
RES 1 $residues
END
END

eof


##create input files for minimization of solvated ionized system
for num in $( seq 1 6); do
E=$(( (6 - $num ) * 5 ))
cat <<eof > $dir/input/min.in.$num
Minimization with $E kcal/mol restraints on solute
 &cntrl
  ncyc=100,
  ntr=1,
  ntx=1,
  ntpr=1,
  ntp=0,
  imin=1,
  maxcyc=100, 
  cut=9,
  ntb=1
 /
Solute is restrained
$E.00000
RES 1 $residues
END
END

eof
done

##create nvt script
cat <<eof > $dir/input/nvt.in
Heat system using NVT
 &cntrl
  nstlim=5000,
  tempi=0,
  temp0=$T,
  ntp=0,
  ntc=2,
  ntwx=200,
  ntpr=50,
  nsnb=20,
  imin=0,
  ntx=1,
  ntwe=200,
  ntr=1,
  ntt=3,
  gamma_ln=1,
  dt=0.002,
  ntb=1,
  ntf=2,
  iwrap=1,
  irest=0
 /
Solute is restrained
10.0000
RES 1 $residues
END
END

eof

## create input file for final equilibration of system prior to start of production
##   dynamics
cat <<eof > $dir/input/npt.in
Equilibrate the system density using NPT for 200 picoseconds
 &cntrl
  ntx=5,
  ntb=2,
  nstlim=37500, 
  ntwe=200, 
  ntpr=50,
  nsnb=20,
  irest=1,
  imin=0,
  ntt=3,
  gamma_ln=1.0,
  tautp=2.0,
  tempi=0.0,
  temp0=$T, 
  dt=0.002,
  ntp=1,
  ntc=2,
  ntwx=200,
  ntf=2,
  ntr=1
  /
END
eof

##create input file for first step of production md
cat <<eof > $dir/input/dyna.randv.sander
Production dynamics with SHAKE
 &cntrl
  ntx=5,
  nstlim=$nstlim,
  ntwe=50,
  ntpr=2000,
  nsnb=10,
  irest=0,
  imin=0,
  ntt=1,
  taup=2.0,
  tautp=10.0,
  tempi=$T,
  temp0=$T,
  dt=$dt,
  ntc=2,
  ntwx=$ntwx,
  ntf=2,
  ioutfm=1,
  iwrap=1,
  ig=-1,
  ntp=0,
  ntb=1
  /
END
eof


##create input file for subsequent steps of production md (continue velocities)
cat <<eof > $dir/input/dyna.irest.sander
Production dynamics with SHAKE
 &cntrl
  ntx=5,
  nstlim=$nstlim,
  ntwe=50,
  ntpr=2000,
  nsnb=10,
  irest=1,
  imin=0,
  ntt=1,
  taup=2.0,
  tautp=10.0,
  tempi=0.0,
  temp0=$T,
  dt=$dt,
  ntc=2,
  ntwx=$ntwx,
  ntf=2,
  ioutfm=1,
  iwrap=1,
  ntp=0,
  ntb=1
  /
END
eof
echo END >> $dir/input/md.in.2

