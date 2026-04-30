
# my question is the following:
# I did normalize PHENO but not PGS
# but what would happen if I normalize them myself
# instead of using the quantile normalization?

NBR_PHENO=40
. .env
run_pgmatch(){
	QPARAM=$1
	PGS_train_curr=$2
	PGS_train_curr_h0=$3
	PGS_test_curr=$4
	PGS_test_curr_h0=$5
	#------------------------------------------------------------------------------#
	# 1. Compute Ce, Cg and r2 on training individuals 
	#------------------------------------------------------------------------------#
	Rscript $PGMATCH/compute_ce_cg_r2.r --pgs $PGS_train_curr --pheno $PHENO_train --r2 $R2 --ce $CE --cg $CG --qnorm $QPARAM

	#------------------------------------------------------------------------------#
	# 2. Compute LLR on training set 
	#------------------------------------------------------------------------------#

	# supervised method
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_train_curr --pheno $PHENO_train --r2 $R2 --ce $CE --llr $SUP_TRAIN_LLR_H1 --qnorm $QPARAM
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_train_curr_h0 --pheno $PHENO_train --r2 $R2 --ce $CE --llr $SUP_TRAIN_LLR_H0 --qnorm $QPARAM

	#------------------------------------------------------------------------------#
	# 3. Compute LLR on testing set
	#------------------------------------------------------------------------------#

	# supervised model
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_curr --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_VALID --qnorm $QPARAM
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_curr_h0 --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_VALID_H0 --qnorm $QPARAM

	#------------------------------------------------------------------------------#
	# 4. Convert LLR to probability
	#------------------------------------------------------------------------------#

	# supervised method
	Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_VALID --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_VALID
	Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_VALID_H0 --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_VALID_H0

}

# with qnorm
#run_pgmatch "T" $PGS_train $PGS_train_h0 $PGS_test $PGS_test_h0
#
## without qnorm
#Rscript Scripts/normalize_mat.r $PGS_train  $(Rscript Scripts/compute_means.r $PGS_train) $(Rscript Scripts/compute_sd.r $PGS_train) $PGS_train_norm
#Rscript Scripts/normalize_mat.r $PGS_train_h0  $(Rscript Scripts/compute_means.r $PGS_train) $(Rscript Scripts/compute_sd.r $PGS_train) $PGS_train_norm_h0
#Rscript Scripts/normalize_mat.r $PGS_test $(Rscript Scripts/compute_means.r $PGS_train) $(Rscript Scripts/compute_sd.r $PGS_train) $PGS_test_norm
#Rscript Scripts/normalize_mat.r $PGS_test_h0 $(Rscript Scripts/compute_means.r $PGS_train) $(Rscript Scripts/compute_sd.r $PGS_train) $PGS_test_norm_h0

#run_pgmatch "F" $PGS_train_norm $PGS_train_norm_h0 $PGS_test_norm $PGS_test_norm_h0

# Plot one against the other
