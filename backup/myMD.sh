#!/bin/bash -eu
##----------------------------------------------------------------------
# Utility function for failing with a useful message

function fail() {
    msg=${1:='No reason given'};
    echo "Your AMBER job failed: $msg"
    exit 1
}

## The base directory for all jobs should be your personal data space
if [ ! -d $DATA ]; then
    fail "Please add the following to your .bashrc\n"\
    "export DATA=/data/<userid>/"
fi
_basedir_=$DATA

## Utility function for generating a usage message
function usage() {
	me=`basename $0`
	cat << END_USAGE

$me [OPTIONS] PDB_FILE

OPTIONS:
  -w FLOAT     Number of Angstroms of water in box
  -g INTEGER   Number of gpus per nodes.  Default is 1.  Max is 3.
  -h or -?     Show this help message
  -j INTEGER   Number of nodes to run on.  Default is 1.  Max is 12.
  -k INTEGER   Number of cpus (cores). Default is 1.
  -l INTEGER   Set number of steps (nstlim) . Default is 2,000,000 and is run i times
  -n NAME      Name of this analysis. Default is username-YYYYMMDD.HHMMSS
  -p           Protonate histidines
  -r           Reduce all CYS's
  -P           Constant Pressure (1 atm)i
  -c           Continue previous simulation
  -R	       Repeat a previous simulation, with a new random seed
  -m           Prep and minimization only
  -s           Stepsize in picoseconds (default is 0.002, not used with -c)
  -i	       Iterations (default is 25)
  -t INTEGER   Set solvent temperature (K).  Default is 300
  -v           Be verbose
  -x INTEGER   Set ntwx. Default is 5000
this means that each step of the output trajectory is 30ps
and will run for 100ns.
END_USAGE

}

#----------------------------------------------------------------------
# Define defaults

_water_=10
_name_="$USER-$(date +%Y%m%d.%H%M%S)"
_cores_=1
_gpus_=1
_reduced_=n
_protonate_=n
_pressure_=n
_timestep_=0.003
_temperature_=300
_nstlim_=20000000 #60 ns
_ntwx_=5000
_iterations_=10
_stage_=""
_dir_="$_basedir_/$_name_"

#----------------------------------------------------------------------
# Process options, alter defaults if the user gives input

while getopts w:n:k:g:rpPt:T:l:x:i: OPTION
do
    case $OPTION in
        w) _water_=$OPTARG;;
        n) _name_=$OPTARG;;
    	k) _cores_=$OPTARG;;
        g) _gpus_=$OPTARG;;
        r) _reduced_=y;;
        p) _protonate_=y;;
        P) _pressure_=y;;
    	t) _timestep_=$OPTARG;;
        T) _temperature_=$OPTARG;;
        l) _nstlim_=$OPTARG;;
        x) _ntwx_=$OPTARG;;
        i) _iterations_=$OPTARG;;
        
    	*) usage; exit;;
    esac
done

# $1 now points to the first non-option argument
shift $(($OPTIND - 1))

#----------------------------------------------------------------------
##check if there is any previous production output
## if so, figure out how many output files
if [ -d $_dir_/PRODUCTION ]
    nc=$( ls $_dir_/PRODUCTION/dyna.*.traj.nc | wc -l )
    prv=$(printf %02d `expr $nc`)
elif [ -d $_dir_/EQUILIBRATION ]
fi

## export variables
for var in water nodes gpus protonate pressure reduced timestep temperature nstlim cores ntwx iterations name sourcedir dir stage nc prv; do
    export _${var}_
done

## function for starting jobs
function runjob() {
    # Slurm
    output=$(sbatch --job-name=$jobname \
      --np $_ntasks_ \
      --gres=gpu:k20x:$_gpus_ \
      --mail-type=END \
      --dependency=afterok:$DEP \
      --workdir="$_dir_" \
      $script)
    startjob=$(echo $output | cut -f4 -d' ')
    echo $startjob
    exit 1
}

while [ "$_stage_" -ne "cont" ]; do
    case "$_stage_" in
        prod)
            npt=$_dir_/EQUILIBRATION/$_name_.npt.crd
            if [ "$_nc_" -gt 0 ]; then        
                echo "found $nc previous output files"
                fail "Please restart with --stage cont"
            elif [ ! -f $npt ]; then
                echo "No previous NPT equilibration output"
                fail "Please finish equilibration and try again"
            else
                jobname="$_name_.prod"
                script="$_sourcedir_/subscripts/prod.sh"
                coord="EQUILIBRATION/$_name_.npt.crd"
                echo "Starting production run from NPT equilibration output"
                runjob $jobname $script
            fi ;;
        npt)
            nvt=$_dir_/EQUILIBRATION/$_name_.nvt.crd
            if [ -f  $nvt ]; then
                echo Consider canceling and re
            elif ["$eqfiles" -eq 1]; then
                jobname="$_name_.equil2"
                script="$_sourcedir_/subscripts/equil2.sh"
                coord="EQUILIBRATION/$_name_.nvt.crd"
                echo starting density equilibration
            else
                echo No NVT equilibration output to start from
            fi ;;
    esac
done 


#-----------------------------------------------------------------------
# Process arguments
_pdb_=$1
export _pdb_

[[ -e "$_dir_" ]] && fail "Output directory $_workdir_ already exists"

mkdir -p "$_dir_"

mkdir "$_dir_/build" "$_dir_/imin"\
 "$_dir_/input" "$_dir_/EQUILIBRATION" "$_dir_/PRODUCTION"

#----------------------------------------------------------------------
## Copy input files into the work directory 
cp $_pdb_ $_dir_/build
_pdb_=$(basename $_pdb_)
#echo "debug : _pdb_ == $_pdb_"
#----------------------------------------------------------------------
## cd into the work directory.  From now on, this will be the cwd

#cd "$_dir_"

#------------------------------------------------------------------------
# prepare input files for md simulation
# Slurm
# IMPORTANT: job_id is not return value for Slurm. Must be parsed from stdout (apparently)
output=$(sbatch -J "$_name_.prep" \
    -n 1 \
    --mail-type=END \
    --workdir="$_dir_" \
    "$_sourcedir_/subscripts/prep.sh")
prep_job=$(echo $output | cut -f4 -d' ')

if [ "$_minimize_" = 'y' ]; then
  exit
fi

#------------------------------------------------------------------------
# finish equilibration runs in prep for md

# Slurm
output=$(sbatch -J "$_name_.equil" \
    -n $_cores_ \
    --nodes=$_nodes_ \
    --mail-type=END \
    --dependency=afterok:$prep_job \
    --workdir="$_dir_" \
    "$_sourcedir_/subscripts/equil.sh")
equil_job=$(echo $output | cut -f4 -d' ')
#------------------------------------------------------------------------
# start md runs
# Slurm
output=$(sbatch -J "$_jobname_" \
    -n $_cores_ \
    --nodes=$_nodes_ \
    --gres=gpu:$_gpus_ \
    --mail-type=END \
    $depend \
    --workdir="$_dir_" \
    $stage)
prod_job=$(echo $output | cut -f4 -d' ')

fi

first=$(ls $_dir_/PRODUCTION/dyna.*.traj.nc 2> /dev/null | wc -l)                             
prv=`printf %02d $first`                                                         
cur=`printf `expr %02d $prv + 1``

 if [ $prv -eq 0 ]; then                                                         
      33     coord="EQUILIBRATION/$_name_.equil.crd.2"                                   
       34 else                                                                            
        35     coord="PRODUCTION/dyna.$cur.out"                                            
         36 for i in $(seq $cur 1 $_iterations_);                                           
#------------------------------------------------------------------------
# All done

