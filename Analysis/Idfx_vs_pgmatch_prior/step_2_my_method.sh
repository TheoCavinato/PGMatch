
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
mkdir -p $SCRATCH/$PARAM_FOLDER/My_method/

#------------------------------------------------------------------------------#
# 1. Compute Ce, Cg and r2 on training individuals
#------------------------------------------------------------------------------#
Rscript $PGMATCH/compute_ce_cg_r2.r --pgs $PGS_train --pheno $PHENO_train --r2 $R2 --ce $CE --cg $CG

#------------------------------------------------------------------------------#
# 2. Compute LLR 
#------------------------------------------------------------------------------#
Rscript $PGMATCH/llr_computation.r --pgs $PGS_train --pheno $PHENO_train --r2 $R2 --ce $CE --llr $TRAIN_LLR
Rscript $PGMATCH/llr_computation.r --pgs $PGS_train_h0 --pheno $PHENO_train --r2 $R2 --ce $CE --llr $TRAIN_LLR_H0

Rscript $PGMATCH/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR_H0

#------------------------------------------------------------------------------#
# 3. Convert to probas
#------------------------------------------------------------------------------#
Rscript $PGMATCH/llr2probas.r --llr_test $TEST_LLR --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR --round 10 --probas $SUP_PROBAS
Rscript $PGMATCH/llr2probas.r --llr_test $TEST_LLR_H0 --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR --round 10 --probas $SUP_PROBAS_H0

