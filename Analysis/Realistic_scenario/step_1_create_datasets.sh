#!/bin/bash
#SBATCH --job-name CreateDataset
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 40G
#SBATCH --cpus-per-task 48
#SBATCH --time 00:30:00
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
ITR=$4

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
	--seed $ITR\
	--out_pheno_10K $PHENO_10K\
	--out_pgs_10K $PGS_10K\
	--out_pheno_train $PHENO_train\
	--out_pgs_train $PGS_train\
	--out_pgs_train_h0 $PGS_train_h0\
	--out_pheno_test $PHENO_test\
	--out_pgs_test $PGS_test\
	--out_pgs_test_h0 $PGS_test_h0

#------------------------------------------------------------------------------#
# Make the wheel turn so that we generate enough mismatches (100e3 * 1e3)
#------------------------------------------------------------------------------#

export NBR_PHENO N_TEST N_TRAIN ITR
seq 0 999 | xargs -n 1 -P 47 bash -c '
	module load r-light
	WHEEL_IDX=$1
	echo $WHEEL_IDX
	. .env
	Rscript Scripts/wheel.r --pgs_p $PGS_test \
		--idx $WHEEL_IDX \
		--out_pgs $PGS_test_h0_wheeled
' _

echo "Simulations done!"

