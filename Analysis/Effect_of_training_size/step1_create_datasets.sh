#!/bin/bash
#SBATCH --job-name Generate_datasets
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Effect_of_training_size/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Effect_of_training_size/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 8G
#SBATCH --time 00:10:00
#SBATCH --cpus-per-task 1
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

N_TEST=$1
N_TRAIN=$2
NBR_PHENO=$3

# load parameters

for ITR in {1..100}; do
	. .env 
	mkdir -p $ITR_FOLDER/Datasets
	awk -F '\t' 'NR>1{ if($1 != 30180 ) {print}}' $VAR_EXPL_NO_CORR | head -n $NBR_PHENO > $USED_PHENO  # remove lymphocyte percentage (because we already have lymphocyte count)

done

#------------------------------------------------------------------------------#
# 1. Create dataset based on real data
#------------------------------------------------------------------------------#

. .env
Rscript Scripts/create_datasets.r\
	--info_p $USED_PHENO\
	--n_test $N_TEST\
	--n_train $N_TRAIN\
	--caucasians_p $CAUCAS \
	--gwas_sample_p $GWAS_CAUCAS \
	--sex_p $SEX \
	--out_pheno_train $PHENO_train\
	--out_pgs_train $PGS_train\
	--out_pgs_train_h0 $PGS_train_h0\
	--out_pheno_test $PHENO_test\
	--out_pgs_test $PGS_test\
	--out_pgs_test_h0 $PGS_test_h0 \
	--seed $RANDOM

## few valisations of the dataset
## validation 1: the ones that should haeve the same IIDs
#check_diff_iids(){
#	echo $(basename $1) $(basename $2)
#	diff <(zcat $1 | awk '{print $1}') <(zcat $2 | awk '{print $1}')
#}
#check_diff_iids $PHENO_train $PGS_train 
#check_diff_iids $PHENO_test $PGS_test 
#
## validation 2: the ones that should have shifted ids
#check_diff_iids $PHENO_test $PGS_test_h0
#check_diff_iids $PGS_test $PGS_test_h0
#check_diff_iids $PHENO_train $PGS_train_h0
#check_diff_iids $PGS_train $PGS_train_h0
#
## valisation 3: the ones that should be completely different
#check_complete_diff(){
#cat <(zcat $1 | awk 'NR>1{print $1}') <(zcat $2 | awk 'NR>1{print $1}') | sort | uniq | wc -l
#}
#
#check_complete_diff $PHENO_train $PHENO_test
#check_complete_diff $PGS_train $PGS_test
#
