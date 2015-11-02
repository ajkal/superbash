#!/bin/bash -eu
#change the following line to data directory
_workdir_=$DATA

#----------------------------------------------------------------------
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
# Utility function for failing with a useful message

function fail() {
    msg=${1:='No reason given'};
    echo "Your hotspot analysis failed: $msg"
    exit 1
}

#----------------------------------------------------------------------
# Define defaults

_water_=10
_infile_=""
_name_="$USER-$(date +%Y%m%d.%H%M%S)"
_nodes_=1
_cores_=1
_gpus_=1
_reduced_=n
_protonate_=n
_pressure_=n
_cont_=n
_prod_=0
_equil_=0
_min_=1
_minimize_=n
_stepsize_=0.003
_temperature_=300
_nstlim_=20000000 #60 ns
_ntwx_=5000
_iterations_=10

#----------------------------------------------------------------------
# Process options, alter defaults if the user want to model the entire Fab

while getopts w:g:j:l:n:pPcrms:t:k:x:i:R: OPTION
do
    case $OPTION in
        w) _water_=$OPTARG;;
        g) _gpus_=$OPTARG;;
        j) _nodes_=$OPTARG;;
        l) _nstlim_=$OPTARG;;
    	k) _cores_=$OPTARG;;
        n) _name_=$OPTARG;;
        p) _protonate_=y;;
        P) _pressure_=y;;
        c) _cont_=y;;
    	R) _repeat_=$OPTARG;;
        r) _reduced_=y;;
        m) _minimize_=y;;
    	s) _stepsize_=$OPTARG;;
        t) _temperature_=$OPTARG;;
        x) _ntwx_=$OPTARG;;
        i) _iterations_=$OPTARG;;
    	*) usage; exit;;
    esac
done

# $1 now points to the first non-option argument
shift $(($OPTIND - 1))

#----------------------------------------------------------------------
## Export variables

for var in water nodes gpus protonate pressure cont repeat reduced stepsize temperature nstlim cores ntwx iterations minimize name sourcedir dir; do
    export _${var}_
done

_dir_="$_workdir_/$_name_"

mdfiles=$(ls $_dir_/PRODUCTION/dyna.*.traj.nc 2> /dev/null | wc -l)
eqfiles=$(ls $_dir_/EQUILIBRATION/$_name_.equil.traj.* 2> /dev/null | wc -l) 
sdep=""                                                                         
swork=""                                                                        
stage=""                                                                        

while [ "$_stage_" -ne "" ]
    
    if [ "$_stage_" -e "prod" && "$eqfiles" -eq 2 ]
        
        if [ "$mdfiles" -gt 0 ]; then
            echo -e "found $mdfiles previous output files"
            echo continuing production run...
            # restart production md runs from last traj restart file
            # Slurm
            jobname="$_name_.cont"
            stage="$_sourcedir_/subscripts/cont.sh"
        else
            fail "no production files to continue from"
    sprod)
        echo starting production run from equilibration output 
        # start production md run from equilibration files
        # Slurm 
        jobname="$_name_.prod"
        stage="$_sourcedir_/subscripts/prod.sh")
    equil2)
        if [ "$eqfiles" -eq 1 ]; then
            echo density equilibration not started, running now...
            # finish equilibration runs in prep for md
            # Slurm
            jobname="$_name_.equil" \
            stage="$_sourcedir_/subscripts/equil2.sh"
        else
            fail "too many or too few equilibration files"
    equil1)
        if [ "$eqfiles" -eq 0 && "$minfile" -eq 1]; then
        echo equilibration has not started, running now...
        # finish equilibration runs in prep for md
        # Slurm
        jobname="$_name_.equil" \
        stage="$_sourcedir_/subscripts/equil.sh"
  else
    
    echo you should never get this error message...
fi
    
    # start production md runs
    # Slurm
    output=$(sbatch -J "$_name_.prod" \
      -n $_cores_ \
      --nodes=$_nodes_ \
      --gres=gpu:$_gpus_ \
      --mail-type=END \
      --dependency=afterok:$equil_job \
      --workdir="$_dir_" \
      "$_sourcedir_/subscripts/prod.sh")
    prod_job=$(echo $output | cut -f4 -d' ')
  else
    echo too many equilibration files
  fi
else

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
#------------------------------------------------------------------------
# All done

