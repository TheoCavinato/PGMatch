#!/bin/bash
#SBATCH --job-name idfx_vs_me_investigation
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_r2_effect/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_r2_effect/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 10G
#SBATCH --cpus-per-task 11
#SBATCH --time 01:10:00
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

R2_FILE=$1

. .env

#------------------------------------------------------------------------------#
# Run all analysis for these parameters
#------------------------------------------------------------------------------#

seq 1 100 | xargs -I {} -P 10 bash -c '
bash step1_create_dataset.sh "$0" "{}" &&
bash step2_my_method.sh "$0" "{}" &&
bash step3_idfx.sh "$0" "{}"
' "$R2_FILE"
