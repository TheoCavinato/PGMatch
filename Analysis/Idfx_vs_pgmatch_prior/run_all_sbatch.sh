#!/bin/bash
#SBATCH --job-name idfx_vs_pgmatch_investigation
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_prior/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_prior/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 20G
#SBATCH --cpus-per-task 1
#SBATCH --time 01:20:00
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

NBR_PHENO=$1
N_TEST=$2
N_TRAIN=$3
ITR=$4

. .env

#------------------------------------------------------------------------------#
# Run all analysis for these parameters
#------------------------------------------------------------------------------#

#bash step_1_create_datasets.sh $NBR_PHENO $N_TEST $N_TRAIN $ITR 
#bash step_2_my_method.sh $NBR_PHENO $N_TEST $N_TRAIN $ITR  
bash step_3_run_real_idfx.sh $NBR_PHENO $N_TEST $N_TRAIN $ITR 

