#!/bin/bash
#SBATCH --job-name CreateData
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 10G
#SBATCH --time 00:20:00
#SBATCH --cpus-per-task=1
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

N_TEST=$1
N_TRAIN=$2
SEED=$3
NBR_PHENO=40

# load parameters
. .env

# create important directories
mkdir -p $SCRATCH/$PARAM_FOLDER
mkdir -p $SCRATCH/$PARAM_FOLDER/Mapping $SCRATCH/$PARAM_FOLDER/Datasets $SCRATCH/$PARAM_FOLDER/Sort_phenos_by_var

#------------------------------------------------------------------------------#
# Create Trait-GWAS mapping
#------------------------------------------------------------------------------#
awk -F '\t' 'NR>1{ if($1 != 30180 ) {print}}' $VAR_EXPL_NO_CORR | head -n $NBR_PHENO > $USED_PHENO  # remove lymphocyte percentage (because we already have lymphocyte count)  

Rscript Scripts/create_datasets.r\
	--info_p $USED_PHENO\
	--n_test $N_TEST\
	--n_train $N_TRAIN\
	--caucasians_p $CAUCAS \
	--gwas_sample_p $GWAS_CAUCAS \
	--sex_p $SEX \
	--seed $SEED \
	--cov_p $COF \
	--out_pheno_10K $PHENO_10K\
	--out_pgs_10K $PGS_10K\
	--out_pheno_train $PHENO_train\
	--out_pgs_train $PGS_train\
	--out_pgs_train_h0 $PGS_train_h0\
	--out_pheno_test $PHENO_test\
	--out_pgs_test $PGS_test\
	--out_pgs_test_h0 $PGS_test_h0\
	--out_pgs_idfx $PGS_idfx\
	--out_pheno_idfx $PHENO_idfx \
	--out_mapping $MAPPING

zcat $PHENO_train | awk 'BEGIN{print "geno\tpheno"}NR>1{printf $1"\t"$1"\n"}' > $IDS_TRAIN
paste <(zcat $PGS_test_h0 | awk '{print $1}') <(zcat $PHENO_test | awk '{print $1}') | awk 'BEGIN{print "pheno\tgeno\toriginal"}NR>1{printf $1"\t"$2"\t"$1"\n"}' | head -n $((1+N_TEST/2)) > $IDS_TEST
zcat $PGS_test_h0 | awk 'NR>1{printf $1"\t"$1"\t"$1"\n"}' | tail -n $((N_TEST/2)) >> $IDS_TEST
Rscript $IDEFIX_GENERATION --phenotypes-file $PHENO_idfx --sample-coupling-file-exclude $IDS_TRAIN --mix-up-percentage 50 --out $IDS_TEST

