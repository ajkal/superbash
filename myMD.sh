#!/bin/bash
##----------------------------------------------------------------------
# Utility function for failing with a useful message

function fail() {
    msg=${1:='No reason given'};
    echo "Your AMBER job failed: $msg"
    exit 1
}
export -f fail


## Utility function for generating a usage message
function usage() {
	me=`basename $0`
	cat << END_USAGE

$me [OPTIONS] PDB_FILE

OPTIONS:
  -b FLOAT     Box dimensions in angstroms
  -n NAME      Name of this analysis. Default is username-YYYYMMDD.HHMMSS
  -h or -?     Show this help message
  -k INTEGER   Number of cpus (cores). Default is 1.
  -g INTEGER   Number of gpus.  Default is 1.  Max is 2.
  -r           Reduce all CYS's
  -p           Protonate histidines
  -P           Constant Pressure (1 atm)
  -T INTEGER   Set solvent temperature (K).  Default is 300
  -R	       Randomize vel and start new run from previous equilibrated system
  -N           Name of previous job
  -m           Prep and minimization only
  -t           Stepsize in picoseconds (default is 0.003)
  -l INTEGER   Set number of steps (nstlim) . Default is 20,000,000 and is run i times
  -w           Walltime in slurm format (e.g. 24:00:00)
  -x INTEGER   Set ntwx. Default is 5000
  -i	       Iterations (default is 25)
  -s           Stage to start at. Default is prep (start a new AMBER job)
  -a           Option to run aMD
  -v           Verbose

END_USAGE

}

#----------------------------------------------------------------------
# Define defaults

_boxdim_=10
_name_="$USER-$(date +%Y%m%d.%H%M%S)"
_cores_=1
_gpus_=1
_reduced_=n
_protonate_=n
_pressure_=n
_temperature_=300
_randv_=n
_prvname_=""
_minonly_=n
_timestep_=0.003
_nstlim_=20000000 #60ns/round
_walltime_="120:00:00"
_ntwx_=5000 #write every 15 ps
_iterations_=10
_stage_="prep" #default is to assume the user wants to start a new AMBER job
_amd_=n

#----------------------------------------------------------------------
# Process options, alter defaults if the user gives input

while getopts b:n:k:g:rpPT:R:N:t:l:w:x:i:s:a: OPTION
do
    case $OPTION in
        b) _boxdim_=$OPTARG;;
        n) _name_=$OPTARG;;
    	k) _cores_=$OPTARG;;
        g) _gpus_=$OPTARG;;
        r) _reduced_=y;;
        p) _protonate_=y;;
        P) _pressure_=y;;
        T) _temperature_=$OPTARG;;
        R) _randv_=$OPTARG;;
        N) _prvname_=OPTARG;;
    	t) _timestep_=$OPTARG;;
        l) _nstlim_=$OPTARG;;
        w) _walltime_=$OPTARG;;
        x) _ntwx_=$OPTARG;;
        i) _iterations_=$OPTARG;;
        s) _stage_=$OPTARG;;
        a) _amd_=$OPTARG;;
    	*) usage; exit;;
    esac
done

# $1 now points to the first non-option argument
shift $(($OPTIND - 1))
_pdb_=$1
#----------------------------------------------------------------------
## export variables and move to job directory
for var in pdb boxdim name cores gpus reduced protonate pressure temperature randv prvname timestep nstlim walltime ntwx iterations stage amd dir; do
    export _${var}_
done

#-----------------------------------------------------------------------
basedir=`pwd`
_dir_="$basedir/$_name_"

if [ $_stage_ == "prep" ]; then
    [[ -e "$_dir_" ]] && fail "Output directory $_dir_ already exists"

    mkdir -p "$_dir_"
    mkdir "$_dir_/build" "$_dir_/imin"\
     "$_dir_/input" "$_dir_/EQUILIBRATION" "$_dir_/PRODUCTION"
    
    ## Copy input PDB into the work directory
    echo Copying $_pdb_ into $_dir_/build
    cp $_pdb_ $_dir_/build
fi

_pdb_=$(basename $_pdb_)

#----------------------------------------------------------------------

## cd into the work directory.  From now on, this will be the cwd
cd "$_dir_"

module load amber/14-gpu

echo Starting at stage: $_stage_
curstage=$_stage_
## workhorse case statement
while [ $curstage != "fin" ]; do
    case $curstage in
        "prep")
            output=$(sbatch --job-name="${_name_}.prep" \
                --mail-type=END \
                --workdir="$_dir_" \
                --partition=quick \
                ~/bin/prep.sh)
            prep_job=$(echo $output | cut -f4 -d' ')
            curstage="min" ;;
        "min")
            echo Minimization will be run on $_cores_ cores
            if [ $_stage_ == "min" ]; then
                DEP=""
            else 
                DEP="--dependency=afterok:$prep_job"
            fi
            output=$(sbatch --job-name="${_name_}.min" \
                --ntasks=$_cores_ \
                --partition=quick \
                --mail-type=END \
                $DEP \
                --workdir="$_dir_" \
                ~/bin/min.sh)
            min_job=$(echo $output | cut -f4 -d' ')
            curstage="nvt"
            if [ $_minonly_ == 'y' ]; then
                exit 0
            fi ;;
        "nvt")
            echo Heating \(NVT\) will be run on $_gpus_ GPU\(s\)
            if [ $_stage_ == "nvt" ]; then
                DEP=""
            else 
                DEP="--dependency=afterok:$min_job"
            fi
            output=$(sbatch --job-name=${_name_}.nvt \
                --ntasks=1 \
                --partition=gpu \
                --gres=gpu:k20x:$_gpus_ \
                --mail-type=END \
                $DEP \
                --workdir="$_dir_" \
                ~/bin/nvt.sh)
            nvt_job=$(echo $output | cut -f4 -d' ')
            curstage="npt" ;;
        "npt")
            echo Volume equilibration \(NPT\) will be run on $_gpus_ GPU\(s\)
            if [ $_stage_ == "npt" ]; then
                DEP=""
            else 
                DEP="--dependency=afterok:$nvt_job"
            fi
            output=$(sbatch --job-name=${_name_}.npt \
                --ntasks=1 \
                --partition=gpu \
                --gres=gpu:k20x:$_gpus_ \
                --mail-type=END \
                $DEP \
                --workdir="$_dir_" \
                ~/bin/npt.sh)
            npt_job=$(echo $output | cut -f4 -d' ')
            curstage="prod" ;;
        "prod")
            if [ $_stage_ == "prod" ]; then
                DEP=""
            else 
                DEP="--dependency=afterok:$npt_job"
            fi
            if [ $_randv_ == 'y' ] && [ -d $_basedir_/$_prvname_ ]; then
                cp $_basedir_/$_prvname_/input/* $_basedir_/$_name_/input
                cp $_basedir_/$_prvname_/build/* $_basedir_/$_name_/build
            fi
            echo Production MD will be run on $_gpus_ GPUs
            output=$(sbatch --job-name="${_name_}.prod" \
                --partition=quick \
                --mail-type=END \
                --workdir="$_dir_" \
                $DEP \
                ~/bin/prod.sh)
            prod_job=$(echo $output | cut -f4 -d' ')
            curstage="fin" ;;
    esac
done

