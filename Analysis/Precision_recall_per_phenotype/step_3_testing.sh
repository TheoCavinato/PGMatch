#!/bin/bash
#SBATCH --job-name Testing
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 1G
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
mkdir -p $SCRATCH/$PARAM_FOLDER/LLR_computed $SCRATCH/$PARAM_FOLDER/Probas

#------------------------------------------------------------------------------#
# 1. Compute LLR on testing set (respresent the individuals we are interested in)
#------------------------------------------------------------------------------#
# classic (r2 ce)
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR_h0
# r2, ldsc_cg
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $R2 --ce $LDSC_CG --llr $TEST_LLR_R2_LDSC_CG
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $R2 --ce $LDSC_CG --llr $TEST_LLR_R2_LDSC_CG_h0
# h2, ldsc_cg
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $TEST_LLR_H2_LDSC_CG
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $TEST_LLR_H2_LDSC_CG_h0

#------------------------------------------------------------------------------#
# 2. Compute probabilities on testing set
#------------------------------------------------------------------------------#
# supervised
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR --moments $MOMENTS_SUP --probas $PROBA_SUP --round 10
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_h0 --moments $MOMENTS_SUP --probas $PROBA_SUP_h0 --round 10
# unsupervised r2, ce, cg
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR --moments $MOMENTS_UNSUP_R2_CE_CG --probas $PROBA_UNSUP_R2_CE_CG --round 10
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_h0 --moments $MOMENTS_UNSUP_R2_CE_CG --probas $PROBA_UNSUP_R2_CE_CG_h0 --round 10
# unsupervised r2, ce, ldsc cg
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR --moments $MOMENTS_UNSUP_R2_CE_LDSC_CG --probas $PROBA_UNSUP_R2_CE_LDSC_CG --round 10
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_h0 --moments $MOMENTS_UNSUP_R2_CE_LDSC_CG --probas $PROBA_UNSUP_R2_CE_LDSC_CG_h0 --round 10
# unsupervised r2, ldsc cg , ldsc cg
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_R2_LDSC_CG --moments $MOMENTS_UNSUP_R2_LDSC_CG_LDSC_CG --probas $PROBA_UNSUP_R2_LDSC_CG_LDSC_CG --round 10
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_R2_LDSC_CG_h0 --moments $MOMENTS_UNSUP_R2_LDSC_CG_LDSC_CG --probas $PROBA_UNSUP_R2_LDSC_CG_LDSC_CG_h0 --round 10
# unsupervised h2, ldsc cg, ldsc cg
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_H2_LDSC_CG --moments $MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG --probas $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG --round 10
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_H2_LDSC_CG_h0 --moments $MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG --probas $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_h0 --round 10

