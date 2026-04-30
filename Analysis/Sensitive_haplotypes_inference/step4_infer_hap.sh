#!/bin/bash
#SBATCH --job-name Infer_haploitypes
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 8G
#SBATCH --time 00:50:00
#SBATCH --cpus-per-task 1
#SBATCH --get-user-env=L
#SBATCH --export NONE


NBR_PHENO=40
ITR=$1
module load r-light

. .env

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#


#------------------------------------------------------------------------------#
# Merge data
#------------------------------------------------------------------------------#

#Rscript Scripts/merge_haps.r $MERGED_HAPS

#------------------------------------------------------------------------------#
# Run analyiss
#------------------------------------------------------------------------------#

Rscript Scripts/infer_hap.r "sup" $N_PHENO_FOLDER $INFERED_HAP_SUP
Rscript Scripts/infer_hap.r "unsup" $N_PHENO_FOLDER $INFERED_HAP_UNSUP


cut -f 1 $N_PHENO_FOLDER/Datasets/pgs.test.sup_scaled.tsv  | head -n1001 | gzip -c >  $ID_HAP
#------------------------------------------------------------------------------#
# Infer phenotype using glm
#------------------------------------------------------------------------------#

