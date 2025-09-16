#!/bin/bash
#SBATCH --job-name Testing
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem  40G
#SBATCH --cpus-per-task 48
#SBATCH --time 00:50:00
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
# classic (r2 ce) H1
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR
# h2, ldsc_cg H1
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $TEST_LLR_H2_LDSC_CG

# H0
export NBR_PHENO N_TEST N_TRAIN ITR
seq 0 999 | xargs -n 1 -P 47 bash -c '
	echo $1
	module load r-light
	WHEEL_IDX=$1
	. .env
	Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test_h0_wheeled --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR_h0_wheeled
	Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test_h0_wheeled --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $TEST_LLR_H2_LDSC_CG_h0_wheeled
' _

#------------------------------------------------------------------------------#
# 2. Compute probabilities on testing set
#------------------------------------------------------------------------------#
# supervised H1
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR --moments $MOMENTS_SUP --probas $PROBA_SUP --round 10
# unsupervised h2, ldsc cg, ldsc cg H1
Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_H2_LDSC_CG --moments $MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG --probas $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG --round 10

# H0
seq 0 999 | xargs -n 1 -P 47 bash -c '
	echo $1
	module load r-light
	WHEEL_IDX=$1
	. .env

	Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_H2_LDSC_CG_h0_wheeled --moments $MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG --probas $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_h0_wheeled --round 10
	Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_h0_wheeled --moments $MOMENTS_SUP --probas $PROBA_SUP_h0_wheeled --round 10
' _
