#!/bin/bash
#SBATCH --job-name Training
#SBATCH --partition urblauna
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/logs/%x_%A-%a.err
#SBATCH --mem 3G
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
BIOBANK_SIZE=$5

# load parameters
. .env 

# create necessary directories
mkdir -p $SCRATCH/$PARAM_FOLDER $DATA/Results

#------------------------------------------------------------------------------#
# 0. Validation before starting (run it only once)
##------------------------------------------------------------------------------#
## make sure that the individuals in the dataset from ../Case_scenario_1_biobank
## are also part of the APOE status
#
#zcat $PHENO_test | awk 'NR>1{print $1}' > $PHENO_test_samples
#PHENO_test_count=$(wc -l < $PHENO_test_samples)
#MATCH_test_count=$(cat $PHENO_test_samples $SAMPLE1 | sort | uniq -c |\
#	awk '{if($1==2) print $0}' |\
#	wc -l)
#if [ $PHENO_test_count -ne $MATCH_test_count ]; then
#	echo "ERROR: the data we had from the ../Case_scenario_1_biobank cannot be used"
#	exit 1
#fi
#
#------------------------------------------------------------------------------#
# 1. Run computation of the weighted average
#------------------------------------------------------------------------------#

#Rscript Scripts/weighted_avg.r --pgs_p $PGS_test \
#	--pheno_p $APOE_STATUS_PER_IND \
#	--prefix_proba $PREFIX_PROBA_SUP_target \
#	--suffix ".tsv.gz" \
#	--biobank_size $BIOBANK_SIZE \
#	--out_tsv $TSV_APOE_INFERENCE &
#
#Rscript Scripts/weighted_avg.r --pgs_p $PGS_test \
#	--pheno_p $APOE_STATUS_PER_IND \
#	--prefix_proba $PREFIX_PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_target \
#	--suffix ".tsv.gz" \
#	--biobank_size $BIOBANK_SIZE \
#	--out_tsv $TSV_APOE_INFERENCE_UNSUP &
#
#wait

##------------------------------------------------------------------------------#
## 2. Compute precision/recall
##------------------------------------------------------------------------------#
#TSV_INFS=($TSV_APOE_INFERENCE $TSV_APOE_INFERENCE_UNSUP)
#TSV_PRECS=($TSV_PREC_REC $TSV_PREC_REC_UNSUP)
#for IDX in ${!TSV_INFS[@]}; do
#	Rscript Scripts/precision_recall.r --inference_p ${TSV_INFS[$IDX]} \
#		--out_tsv ${TSV_PRECS[$IDX]} &
#done
#wait
#
#for TSV_PREC in ${TSV_PRECS[@]}; do
#	cp $TSV_PREC $TMP	
#done

#------------------------------------------------------------------------------#
# 3. Plot results
#------------------------------------------------------------------------------#

Rscript Scripts/plot_inference.r \
	--inference_sup $TSV_APOE_INFERENCE \
	--inference_unsup $TSV_APOE_INFERENCE_UNSUP \
	--out_boxplot_with $PDF_BOXPLOT_WITH \
	--out_boxplot_without $PDF_BOXPLOT_WITHOUT

# export it for ssh
cp $PDF_BOXPLOT_WITH $TMP
cp $PDF_BOXPLOT_WITHOUT $TMP
