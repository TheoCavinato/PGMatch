
#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

R2_FILE=$1
ITR=$2

. .env

mkdir -p $MY_METHOD_FOLDER

#------------------------------------------------------------------------------#
# 1. Compute Ce, Cg and r2 on 10K individuals (represent valus we would know from another dataset)
#------------------------------------------------------------------------------#
#Rscript $PGMATCH/compute_ce_cg_r2.r --pgs $PGS_TRAIN_H1 --pheno $PHENO_TRAIN --r2 $R2 --ce $CE --cg $CG
Rscript $PGMATCH/compute_ce_cg_r2.r --pgs $PGS_TRAIN_H1 --pheno $PHENO_TRAIN --r2 $R2 --ce $CE --cg $CG

#------------------------------------------------------------------------------#
# 2. Compute LLR on training set (represent a subset of individuals we have access to)
#------------------------------------------------------------------------------#

# normal method
Rscript $PGMATCH/llr_computation.r --pgs $PGS_TRAIN_H1 --pheno $PHENO_TRAIN --r2 $R2 --ce $CE --llr $TRAIN_LLR_H1
Rscript $PGMATCH/llr_computation.r --pgs $PGS_TRAIN_H0 --pheno $PHENO_TRAIN --r2 $R2 --ce $CE --llr $TRAIN_LLR_H0

#------------------------------------------------------------------------------#
# 4. Testing
#------------------------------------------------------------------------------#
Rscript $PGMATCH/llr_computation.r --pgs $PGS_TEST_H0 --pheno $PHENO_TEST --r2 $R2 --ce $CE --llr $TEST_LLR_H0
Rscript $PGMATCH/llr_computation.r --pgs $PGS_TEST_H1 --pheno $PHENO_TEST --r2 $R2 --ce $CE --llr $TEST_LLR_H1

#------------------------------------------------------------------------------#
# 5. Probas
#------------------------------------------------------------------------------#
Rscript $PGMATCH/llr2probas.r --llr_test $TEST_LLR_H0 --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR_H1 --round 10 --probas $SUP_PROBAS_H0
Rscript $PGMATCH/llr2probas.r --llr_test $TEST_LLR_H1 --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR_H1 --round 10 --probas $SUP_PROBAS_H1


concat_proba(){
awk 'BEGIN{OFS="\t"; print "proba","truth"}
	{print $2, (ARGIND==1 ? "H0" : "H1")}' <(zcat $1 | tail -n +2) <(zcat $2 | tail -n +2) |\
	gzip -c > $3
}

concat_proba $SUP_PROBAS_H0 $SUP_PROBAS_H1 $SUP_PROBAS

