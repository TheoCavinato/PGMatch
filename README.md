# Re-iodentification by polygenic predictions

Code supporting the paper entitled "Assessing the real threat of re-identification by polygenic predictions".
In the main directory are the scripts an attacker could use to re-identify a genome


- `compute_ce_cg_r2.r --pgs $PGS_10K --pheno $PHENO_10K --r2 $R2 --ce $CE --cg $CG
#------------------------------------------------------------------------------#
# 2. Compute Ce, Cg and r2 on 10K individuals (represent valus we would know from another dataset)
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
# 3. Compute LLR on training set (represent a subset of individuals we have access to)
#------------------------------------------------------------------------------#
Rscript llr_computation.r --pgs $PGS_train --pheno $PHENO_train --r2 $R2 --ce $CE --llr $TRAIN_LLR
Rscript llr_computation.r --pgs $PGS_train_h0 --pheno $PHENO_train --r2 $R2 --ce $CE --llr $TRAIN_LLR_H0

#------------------------------------------------------------------------------#
# 4. Get moments
#------------------------------------------------------------------------------#
Rscript moments_supervised.r --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR --moments $MOMENTS_SUP
Rscript moments_unsupervised.r --r2 $R2 --ce $CE --cg $CG --moments $MOMENTS_UNSUP

#------------------------------------------------------------------------------#
# 5. Compute LLR on testing set (respresent the individuals we are interested in)
#------------------------------------------------------------------------------#
Rscript llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR
Rscript llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR_H0


