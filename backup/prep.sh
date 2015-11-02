#!/bin/bash -ue
#---------------------------------------------------------------------
## protonate the histidines if needed
egrep -v 'REMARK|EXPDTA' build/$_pdb_ > build/tmp1
reduce -trim build/tmp1 > build/tmp2
if [[ $_protonate_ = 'n' ]]
then
  sed 's/HIS/HIE/g' build/tmp2 > build/tmp3
else
  sed 's/HIS/HIP/g' build/tmp2 > build/tmp3
fi
mv build/tmp3 build/$_name_.1.pdb
rm build/tmp*

#----------------------------------------------------------------------
# The amber module provides tleap and friends

#module load apps/amber/12

#----------------------------------------------------------------------
## have tleap load $_gne_hs_fab_.1 and make pdb called build/$_gne_hs_fab_.leap1.pdb with new numbering
$_sourcedir_/subscripts/make.leap.in.1 $PWD
tleap -f input/leap.in.1
ambpdb -p build/leap1.top < build/leap1.crd > build/leap1.pdb

#----------------------------------------------------------------------
## correctly link disulfides and make pdb, top and crd files:  build.$_gne_hs_fab_.stripped.type
$_sourcedir_/subscripts/make.leap.in.2 $PWD
tleap -f input/leap.in.2
ambpdb -p build/$_name_.stripped.top < build/$_name_.stripped.crd > build/$_name_.stripped.pdb

#------------------------------------------------------------------------
## load minimized structure add ions to neutralize and add waters
## output files are build/$_gne_hs_fab_.water.top, build/$_gne_hs_fab_.water.crd and a pdb

$_sourcedir_/subscripts/make.leap.in.3 $PWD
tleap -f input/leap.in.3

tail -3 build/leap1.pdb > build/tmp.txt
residues=$(awk '{ print $5 }' build/tmp.txt)
rm build/tmp.txt

#----------------------------------------------------------------------
## make the amber input scripts in /input

$_sourcedir_/subscripts/make.input.sh \
    $PWD \
    $_temperature_ \
    $_nstlim_      \
    $_timestep_      \
    $_ntwx_     \
    $residues  \
    $_pressure_ 
