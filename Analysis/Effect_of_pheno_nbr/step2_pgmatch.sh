#!/bin/bash
#SBATCH --job-name PGMatch
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 4G
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

#------------------------------------------------------------------------------#
# Run
#------------------------------------------------------------------------------#

run_pgmatch(){
	ITR=$1
	. .env

	mkdir -p $ITR_FOLDER/PGMatch_results


	#------------------------------------------------------------------------------#
	# 1. Compute Ce, Cg and r2 on training individuals 
	#------------------------------------------------------------------------------#
	Rscript $PGMATCH/compute_ce_cg_r2.r --pgs $PGS_train --pheno $PHENO_train --r2 $R2 --ce $CE --cg $CG

	#------------------------------------------------------------------------------#
	# 2. Compute LLR on training set 
	#------------------------------------------------------------------------------#

	# supervised method
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_train --pheno $PHENO_train --r2 $R2 --ce $CE --llr $SUP_TRAIN_LLR_H1
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_train_h0 --pheno $PHENO_train --r2 $R2 --ce $CE --llr $SUP_TRAIN_LLR_H0

	# unsupervised model
	Rscript Scripts/format_ldsc_r2.r --pheno_file $R2 --ori_ldsc_cg $ORI_LDSC_CG --ori_ldsc_cv $ORI_LDSC_CV --h2 $LDSC_H2 --ldsc_cg $LDSC_CG
	Rscript $PGMATCH/llr_simulation.r --r2 $LDSC_H2 --ce $LDSC_CG --cg $LDSC_CG --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --n_sim $N_TRAIN

	# comment from reviewer 2
	Rscript $PGMATCH/llr_simulation.r --r2 $LDSC_H2 --ce $CE --cg $LDSC_CG --llr_h0 $REVIEWER2_UNSUP_TRAIN_LLR_H0 --llr_h1 $REVIEWER2_UNSUP_TRAIN_LLR_H1 --n_sim $N_TRAIN

	#------------------------------------------------------------------------------#
	# 3. Compute LLR on testing set
	#------------------------------------------------------------------------------#

	# supervised model
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_H1
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_H0

	# unsupervised method
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $UNSUP_TEST_LLR_H1
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $UNSUP_TEST_LLR_H0

	# comment from reviewr 2
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $LDSC_H2 --ce $CE --llr $REVIEWER2_UNSUP_TEST_LLR_H1
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $LDSC_H2 --ce $CE --llr $REVIEWER2_UNSUP_TEST_LLR_H0

	#------------------------------------------------------------------------------#
	# 4. Convert LLR to probas using Kernel Density Estimation
	#------------------------------------------------------------------------------#

	# supervised method
	Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_H0 --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_H0
	Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_H1 --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_H1

	# unsupervised method
	Rscript $PGMATCH/llr2probas.r --llr_test $UNSUP_TEST_LLR_H0 --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --round 10 --probas $UNSUP_PROBA_H0
	Rscript $PGMATCH/llr2probas.r --llr_test $UNSUP_TEST_LLR_H1 --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --round 10 --probas $UNSUP_PROBA_H1

	# comment from reviewer 2
	Rscript $PGMATCH/llr2probas.r --llr_test $REVIEWER2_UNSUP_TEST_LLR_H0 --llr_h0 $REVIEWER2_UNSUP_TRAIN_LLR_H0 --llr_h1 $REVIEWER2_UNSUP_TRAIN_LLR_H1 --round 10 --probas $REVIEWER2_UNSUP_PROBA_H0
	Rscript $PGMATCH/llr2probas.r --llr_test $REVIEWER2_UNSUP_TEST_LLR_H1 --llr_h0 $REVIEWER2_UNSUP_TRAIN_LLR_H0 --llr_h1 $REVIEWER2_UNSUP_TRAIN_LLR_H1 --round 10 --probas $REVIEWER2_UNSUP_PROBA_H1
}

export -f run_pgmatch
export N_TEST N_TRAIN NBR_PHENO

seq 1 100 | xargs -n 1 -P 10 -I {} bash -c 'run_pgmatch "$@"' _ {}
