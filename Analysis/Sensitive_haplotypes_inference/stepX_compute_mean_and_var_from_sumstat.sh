#!/bin/bash
#SBATCH --job-name Compute_mean_var
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 150G
#SBATCH --time 01:10:00
#SBATCH --cpus-per-task 11
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light


NBR_PHENO=40

while read line; do
	PHENO_ID=$(echo $line | awk '{print $1}')
	. .env
	echo $PHENO_ID $ESTIMATED_MEAN_AND_VAR
done < $USED_PHENO > xarg_file

xargs -P 10 -n 2 -a xarg_file Rscript Scripts/compute_mean_from_sumstat.r 
