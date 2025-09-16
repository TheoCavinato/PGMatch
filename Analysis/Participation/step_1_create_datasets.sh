#!/bin/bash
#SBATCH --job-name CreateDataset
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 4G
#SBATCH --time 00:10:00
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
SEED=$4

# load parameters
. .env 

# create directories if necessary
mkdir -p $SCRATCH/$PARAM_FOLDER/Sort_phenos_by_var/ $SCRATCH/$PARAM_FOLDER/Datasets/

#------------------------------------------------------------------------------#
# Create datasets
#------------------------------------------------------------------------------#
awk -F '\t' 'NR>1{ if($1 != 30180 ) {print}}' $VAR_EXPL_NO_CORR | head -n $NBR_PHENO > $USED_PHENO  # remove lymphocyte percentage (because we already have lymphocyte count)  
Rscript Scripts/create_datasets.r\
	--info_p $USED_PHENO\
	--n_test $N_TEST\
	--n_train $N_TRAIN\
	--caucasians_p $CAUCAS \
	--gwas_sample_p $GWAS_CAUCAS \
	--sex_p $SEX \
	--seed $SEED\
	--out_pheno_10K $PHENO_10K\
	--out_pgs_10K $PGS_10K\
	--out_pheno_train $PHENO_train\
	--out_pgs_train $PGS_train\
	--out_pgs_train_h0 $PGS_train_h0\
	--out_pheno_test $PHENO_test\
	--out_pgs_test $PGS_test

