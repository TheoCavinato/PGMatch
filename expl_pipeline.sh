
# Here is an eample of all the steps required to run the approach

module load r-light 

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

NBR_PHENO=$1

SCRATCH=/scratch/tcavinat/QualitativeTraits_2024_10_07/pheno_vs_pgs/

## 1. create datasets
# input 
SORT_NO_CORR=/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/LLR_approach/Sort_phenos_by_var/sorted_phenos.130Kfilted.no_corr.tsv

# output
mkdir -p $SCRATCH/Sort_phenos_by_var/ $SCRATCH/Datasets/
USED_PHENO=$SCRATCH/Sort_phenos_by_var/phenos.$NBR_PHENO.txt 
PHENO_10K=$SCRATCH/Datasets/pheno.10K.${NBR_PHENO}_phenos.tsv.gz
PGS_10K=$SCRATCH/Datasets/pgs.10K.${NBR_PHENO}_phenos.tsv.gz
PHENO_train=$SCRATCH/Datasets/pheno.train.${NBR_PHENO}_phenos.tsv.gz
PGS_train=$SCRATCH/Datasets/pgs.train.${NBR_PHENO}_phenos.tsv.gz
PHENO_test=$SCRATCH/Datasets/pheno.test.${NBR_PHENO}_phenos.tsv.gz
PGS_test=$SCRATCH/Datasets/pgs.test.${NBR_PHENO}_phenos.tsv.gz
PGS_train_h0=$SCRATCH/Datasets/pgs.train.${NBR_PHENO}_phenos.h0.tsv.gz
PGS_test_h0=$SCRATCH/Datasets/pgs.test.${NBR_PHENO}_phenos.h0.tsv.gz

## 2. compute ce,cg and r2
# output
mkdir -p $SCRATCH/Correlations/
R2=$SCRATCH/Correlations/r2.${NBR_PHENO}_phenos.tsv.gz
CE=$SCRATCH/Correlations/ce.${NBR_PHENO}_phenos.tsv.gz
CG=$SCRATCH/Correlations/cg.${NBR_PHENO}_phenos.tsv.gz

## 3. compute llr
# output
mkdir -p $SCRATCH/LLR_computed
TRAIN_LLR=$SCRATCH/LLR_computed/llr.train.${NBR_PHENO}_phenos.tsv.gz
TRAIN_LLR_H0=$SCRATCH/LLR_computed/llr.train.${NBR_PHENO}_phenos.h0.tsv.gz

## 4. compute moments
mkdir -p $SCRATCH/Moments
MOMENTS_SUP=$SCRATCH/Moments/moments.supervised.${NBR_PHENO}_phenos.tsv
MOMENTS_UNSUP=$SCRATCH/Moments/moments.unsupervised.${NBR_PHENO}_phenos.tsv

## 5. compute llr
TEST_LLR=$SCRATCH/LLR_computed/llr.test.${NBR_PHENO}_phenos.tsv.gz
TEST_LLR_H0=$SCRATCH/LLR_computed/llr.test.${NBR_PHENO}_phenos.h0.tsv.gz

#------------------------------------------------------------------------------#
# 1. Split datasets
#------------------------------------------------------------------------------#
awk 'NR>1{print}' $SORT_NO_CORR | head -n $NBR_PHENO  > $USED_PHENO 
Rscript Scripts/create_datasets.r $USED_PHENO $PHENO_10K $PGS_10K $PHENO_train $PGS_train $PHENO_test $PGS_test $PGS_train_h0 $PGS_test_h0

#------------------------------------------------------------------------------#
# 2. Compute Ce, Cg and r2 on 10K individuals (represent valus we would know from another dataset)
#------------------------------------------------------------------------------#
Rscript compute_ce_cg_r2.r --pgs $PGS_10K --pheno $PHENO_10K --r2 $R2 --ce $CE --cg $CG

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


