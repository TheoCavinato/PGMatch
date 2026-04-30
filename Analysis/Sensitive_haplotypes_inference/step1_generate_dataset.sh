#!/bin/bash
#SBATCH --job-name Create_dataset
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 2G
#SBATCH --time 00:20:00
#SBATCH --cpus-per-task 1
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

N_TEST=100000
N_TRAIN=1000
NBR_PHENO=40
ITR=$1

. .env
#------------------------------------------------------------------------------#
# 1. Create dataset based on real data
#------------------------------------------------------------------------------#

mkdir -p $N_PHENO_FOLDER/Datasets/
awk -F '\t' 'NR>1{ if($1 != 30180 ) {print}}' $VAR_EXPL_NO_CORR | head -n $NBR_PHENO > $USED_PHENO  # remove lymphocyte percentage (because we already have lymphocyte count)

Rscript Scripts/create_datasets.r\
        --info_p $USED_PHENO\
        --n_test $N_TEST\
        --n_train $N_TRAIN\
        --caucasians_p $CAUCAS \
        --gwas_sample_p $GWAS_CAUCAS \
        --sex_p $SEX \
        --out_pheno_train $PHENO_train\
        --out_pgs_train $PGS_train\
        --out_pgs_train_h0 $PGS_train_h0\
        --out_pheno_test $PHENO_test\
        --out_pgs_test $PGS_test\
        --out_pgs_test_h0 $PGS_test_h0 \
        --seed $RANDOM

cp /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/Datasets/estimated_mean* $N_PHENO_FOLDER/Datasets/
