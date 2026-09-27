#!/bin/bash

# slurm parameters
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1000MB
#SBATCH --time=0-00:10:00
#SBATCH --job-name="filename.R params"
#SBATCH --output="out/filename params.out"
#SBATCH --mail-user=a@b.c
#SBATCH --mail-type=END,FAIL

# set up environment
## unload all modules
module purge

## initialize micromamba
eval "$(micromamba shell hook --shell bash)"

## activate micromamba environment
micromamba activate ITCD

# do job
Rscript --vanilla -e "source('R/filename.R', echo = TRUE)" params

# deactivate micromamba environment
micromamba deactivate

# show job information
scontrol show job $SLURM_JOB_ID
