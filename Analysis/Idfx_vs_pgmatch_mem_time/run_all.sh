#!/bin/bash
#SBATCH --job-name Time_comparison_idfx
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_mem_time/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_mem_time/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 15G 
#SBATCH --time 01:10:00
#SBATCH --cpus-per-task 11
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light

N_TEST=$1
N_TRAIN=$2
NBR_PHENO=$3

bash step1_create_dataset.sh "$N_TEST" "$N_TRAIN" "$NBR_PHENO"
seq 1 10 | xargs -I {} -P 1 bash step2_my_method.sh "$N_TEST" "$N_TRAIN" "$NBR_PHENO" {}
seq 1 10 | xargs -I {} -P 1 bash step3_idfx.sh "$N_TEST" "$N_TRAIN" "$NBR_PHENO" {}
