
#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

N_TEST=$1
N_TRAIN=$2
NBR_PHENO=$3
ITR=$4
. .env

mkdir -p $MY_METHOD_FOLDER
mkdir -p $TIME_FOLDER

run_my_method(){
#------------------------------------------------------------------------------#
# 1. Compute Ce, Cg and r2 on 10K individuals (represent valus we would know from another dataset)
#------------------------------------------------------------------------------#
Rscript $PGMATCH/compute_ce_cg_r2.r --pgs $PGS_TRAIN_H1 --pheno $PHENO_TRAIN --r2 $R2 --ce $CE --cg $CG

#------------------------------------------------------------------------------#
# 2. Training
#------------------------------------------------------------------------------#

# supervised method
Rscript $PGMATCH/llr_computation.r --pgs $PGS_TRAIN_H1 --pheno $PHENO_TRAIN --r2 $R2 --ce $CE --llr $TRAIN_LLR_H1
Rscript $PGMATCH/llr_computation.r --pgs $PGS_TRAIN_H0 --pheno $PHENO_TRAIN --r2 $R2 --ce $CE --llr $TRAIN_LLR_H0

#------------------------------------------------------------------------------#
# 4. Testing
#------------------------------------------------------------------------------#

# supervised method
Rscript $PGMATCH/llr_computation.r --pgs $PGS_TEST_H0 --pheno $PHENO_TEST --r2 $R2 --ce $CE --llr $TEST_LLR_H0
Rscript $PGMATCH/llr_computation.r --pgs $PGS_TEST_H1 --pheno $PHENO_TEST --r2 $R2 --ce $CE --llr $TEST_LLR_H1

#------------------------------------------------------------------------------#
# 5. Probas
#------------------------------------------------------------------------------#
Rscript $PGMATCH/llr2probas.r --llr_test $TEST_LLR_H0 --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR_H1 --round 10 --probas $SUP_PROBAS_H0
Rscript $PGMATCH/llr2probas.r --llr_test $TEST_LLR_H1 --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR_H1 --round 10 --probas $SUP_PROBAS_H1
}

#time run_my_method > $TIME_MY_METHOD
export -f run_my_method
export N_TEST N_TRAIN NBR_PHENO ITR
/usr/bin/time -v -o $TIME_MY_METHOD bash -c ". .env; run_my_method" 
rm -r $MY_METHOD_FOLDER
