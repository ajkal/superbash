#!/usr/bin/env Rscript
library(getopt)
spec <- matrix(c(
        'prefix'    , 'p',1, "character",   "Job name prefix (required)",
        'runtime'   , 'r',1, "character",   "Job name prefix (required)",
        'cluster'   , 'c',1, "character",   "Cluster (required)",
        'gpus'      , 'g',1, "integer",     "Number of gpus (required)",
        'nprocs'    , 'n',1, "integer",     "Number of procs (required)",
        'start'     , 's',1, "integer",     "Starting iteration (required)",
        'end'       , 'e',1, "integer",     "Ending iteration (required)",
        'randv'     , 'R',1, "character",   "Option to randomize vel (required)",
        'amd'       , 'a',1, "character",   "Option to run aMD (required)"
),ncol=5,byrow=T)

opt <- getopt(spec)
prefix <- opt$prefix
runtime <- opt$runtime
cluster <- opt$cluster
gpus <- opt$gpus
nprocs <- opt$nprocs
iter <- opt$start:opt$end
randv <- opt$randv
amd <- opt$amd

print(iter)
## Write out a series of slurm jobs
## shell scripts for running AMBER on biowulf2

if (nchar(prefix) > 8) {
    warning(paste("Your filename 'prefix' is over 8 characters in length,\n\t",
                  "consider shortning so iteration digits are visible with squeue"))
}

## Run pmemd aMD on axiom-GPU
slurmfiles <- paste(prefix,".",sprintf("%02.0f", iter),".slurm",sep="")
submitfile <- paste("submit_",prefix,".sh",sep="")
    
for(i in 1:length(iter)) {
print(iter[i])
cat(paste("#!/bin/bash
#SBATCH --job-name=",prefix,"
#SBATCH --mail-user=\"andrew.kalenkiewicz@nih.gov\"
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --export=ALL
#SBATCH --time=",runtime,"

echo Running job name $SLURM_JOB_NAME with ID $SLURM_JOBID on host $SLURM_SUBMIT_HOST
echo Nodes for run:
cat $SLURM_NODELIST
NPROCS=`wc -l < $SLURM_NODELIST`
echo This job has allocated $NPROCS cores
echo Working directory is $SLURM_SUBMIT_DIR
cd $SLURM_SUBMIT_DIR
echo Time is `date`
echo Directory is `pwd`

module load amber/14-gpu

##AMBER=$AMBERHOME/bin/pmemd.cuda
AMBER=$AMBERHOME/bin/pmemd.cuda.MPI
##MPIRUN=$MPI_HOME/bin/mpirun

prv=",sprintf("%02.0f", (iter[i]-1)),"
cur=",sprintf("%02.0f",  iter[i]),"\n",

"AMBER_ARGS=\"-O -p $_name_.sys_box.prmtop ",

if (randv=='y') {
    "-i dyna.randv.sander "
} else {
    "-i dyna.irest.sander "
},
"-c dyna.$prv.rst -o dyna.$cur.out -r dyna.$cur.rst -x dyna.$cur.traj.nc -inf dyna.$cur.inf",
if (amd=='y') {
    " -amd amd.$cur.log"
},
"\"\n$AMBER $AMBER_ARGS

echo Finished at time: `date`\n", sep=""),
  file=slurmfiles[i])
}
      ##-- Write a master submission shell script for dependent jobs
      ## slurmfiles <- paste("r",".",sprintf("%02.0f", iter),".pbs",sep="")
      slurmids <- paste("r", iter, sep="") 
      head <- paste("#!/bin/bash \n",
                    slurmids[1],"=`sbatch  --partition=gpu --gres=gpu:k20x:",gpus," " ,slurmfiles[1],
		    "`\necho $r",iter[1],"\n", sep="")

      middle <- paste(paste(slurmids[-1],"=`sbatch --depend=afterok:$",
		    slurmids[-length(slurmids)],"  --partition=gpu --gres=gpu:k20x:",gpus," ",slurmfiles[-1],
		    "`\necho $",slurmids[-1],"\n", sep=""), collapse="", sep="")
    
      cat(head, middle, file=submitfile)
 
## Running instructions
cat(paste(" *  SCP files to Cluster ",
cluster, "\n\t(including:\t", submitfile, " dyna.",
sprintf("%02.0f", (iter[1]-1)),
".rst sys_box.prmtop and \n\t\t\tdyna_prod.sander or dyna_amd.sander)\n\t",
"(possibly cp dyna_equil.rst  to dyna.00.rst)\n\t",
"> cp dyna_equil.rst dyna.00.rst\n\t",
"> scp dyna.00.rst sys_box.prmtop dyna_prod.sander dyna_amd.sander ",
prefix,".*.pbs submit_",prefix,".sh bgrant@",cluster,":somepath/.\n\n",
" *  Submit all dependent jobs with run script:\n\t> sh ",
submitfile,"\n\n",

" *  Or submit individual jobs with:\n\t> sbatch ",
paste(prefix,".",sprintf("%02.0f", iter[1]),
".sge",sep=""), "\n\t> sbatch -hold_jid <JOBID> ",
paste(prefix,".",sprintf("%02.0f", iter[2]),
".sge",sep=""),"\n\t ...etc...\n\n",sep=""))

