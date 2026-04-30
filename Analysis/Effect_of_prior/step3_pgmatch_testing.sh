#!/bin/bash
#SBATCH --job-name PGMatch_testing
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Effect_of_prior/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Effect_of_prior/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 5G
#SBATCH --time 01:10:00
#SBATCH --cpus-per-task 10
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light


#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

N_TEST=$1
N_TRAIN=$2
NBR_PHENO=$3
ITR=$4

#------------------------------------------------------------------------------#
# Prepare data
#------------------------------------------------------------------------------#

run_test(){
WHEEL=$1
. .env

#------------------------------------------------------------------------------#
# Downsample dataset
#------------------------------------------------------------------------------#

zcat $PGS_test | head -n 1 | gzip -c > $PGS_test_h0
zcat $PGS_test | awk 'NR>1' | tail -n $((N_TEST-WHEEL)) | gzip -c >> $PGS_test_h0
zcat $PGS_test | awk 'NR>1' | head -n $((WHEEL)) | gzip -c >> $PGS_test_h0
if [ $(zcat $PGS_test_h0 | awk '{print $1}' | sort | uniq | wc -l) -ne $((N_TEST+1)) ]; then
	echo "error, not right number of lines in pgs test"
	exit 1
fi

#------------------------------------------------------------------------------#
# 1. Compute LLR on testing set
#------------------------------------------------------------------------------#

# supervised model
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_H0

# unsupervised method
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $UNSUP_TEST_LLR_H0

#------------------------------------------------------------------------------#
# 2. Convert LLR to probas using Kernel Density Estimation
#------------------------------------------------------------------------------#

# supervised method
Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_H0 --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_H0

# unsupervised method
Rscript $PGMATCH/llr2probas.r --llr_test $UNSUP_TEST_LLR_H0 --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --round 10 --probas $UNSUP_PROBA_H0
}

export -f run_test
export N_TEST N_TRAIN NBR_PHENO ITR

seq 1 1000 | xargs -n 1 -P 10 -I {} bash -c 'run_test "$@"' _ {}
