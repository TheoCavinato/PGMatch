#!/bin/bash
#SBATCH --job-name Training
#SBATCH --partition urblauna
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/logs/%x_%A-%a.err
#SBATCH --mem 3G
#SBATCH --time 00:10:00
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light 

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#
# user parameters
NBR_PHENO=$1
N_TEST=$2
N_TRAIN=$3
ITR=$4

# load parameters
. .env 

# create directories if necessary
mkdir -p $SCRATCH/$PARAM_FOLDER/Correlations/ $SCRATCH/$PARAM_FOLDER/LLR_computed/ $SCRATCH/$PARAM_FOLDER/Moments/

#------------------------------------------------------------------------------#
# 1. Compute Ce, Cg and r2 on 10K individuals (represent valus we would know from another dataset)
#------------------------------------------------------------------------------#
Rscript $PHENO_VS_PGS/compute_ce_cg_r2.r --pgs $PGS_10K --pheno $PHENO_10K --r2 $R2 --ce $CE --cg $CG
Rscript Scripts/format_ldsc_r2.r --r2 $R2 --ori_ldsc_cg $ORI_LDSC_CG --ori_ldsc_cv $ORI_LDSC_CV --h2 $LDSC_H2 --ldsc_cg $LDSC_CG

#------------------------------------------------------------------------------#
# 2. Compute LLR on training set (represent a subset of individuals we have access to)
#------------------------------------------------------------------------------#
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_train --pheno $PHENO_train --r2 $R2 --ce $CE --llr $TRAIN_LLR
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_train_h0 --pheno $PHENO_train --r2 $R2 --ce $CE --llr $TRAIN_LLR_H0

#------------------------------------------------------------------------------#
# 3. Get moments
#------------------------------------------------------------------------------#
# supervised model
Rscript $PHENO_VS_PGS/moments_supervised.r --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR --moments $MOMENTS_SUP
# unsupervised using LDSC CG even for CE x H2 instead of R2
Rscript $PHENO_VS_PGS/moments_unsupervised.r --r2 $LDSC_H2 --ce $LDSC_CG --cg $LDSC_CG --moments $MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG

