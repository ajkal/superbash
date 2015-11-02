#!/bin/bash 
r1=`sbatch  --partition=gpu --gres=gpu:k20x:1 hi.01.slurm`
echo $r1
 r2=`sbatch --depend=afterok:$r1  --partition=gpu --gres=gpu:k20x:1 hi.02.slurm`
echo $r2
r3=`sbatch --depend=afterok:$r2  --partition=gpu --gres=gpu:k20x:1 hi.03.slurm`
echo $r3
r4=`sbatch --depend=afterok:$r3  --partition=gpu --gres=gpu:k20x:1 hi.04.slurm`
echo $r4
r5=`sbatch --depend=afterok:$r4  --partition=gpu --gres=gpu:k20x:1 hi.05.slurm`
echo $r5
r6=`sbatch --depend=afterok:$r5  --partition=gpu --gres=gpu:k20x:1 hi.06.slurm`
echo $r6
r7=`sbatch --depend=afterok:$r6  --partition=gpu --gres=gpu:k20x:1 hi.07.slurm`
echo $r7
r8=`sbatch --depend=afterok:$r7  --partition=gpu --gres=gpu:k20x:1 hi.08.slurm`
echo $r8
r9=`sbatch --depend=afterok:$r8  --partition=gpu --gres=gpu:k20x:1 hi.09.slurm`
echo $r9
r10=`sbatch --depend=afterok:$r9  --partition=gpu --gres=gpu:k20x:1 hi.10.slurm`
echo $r10
