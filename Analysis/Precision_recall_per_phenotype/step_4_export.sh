#!/bin/bash
#SBATCH --job-name PrecRecAndExport
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 1G
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
ITR=$4

# load parameters
. .env 

# create directories if necessary
mkdir -p $SCRATCH/$PARAM_FOLDER/Precision_recall
mkdir -p $SCRATCH/$PARAM_FOLDER/Dist_llr/

#------------------------------------------------------------------------------#
# Plot distributions (you cannot plot on ur computer because of space and privacy)
#------------------------------------------------------------------------------#
#Rscript Scripts/distribution.r --llr_test $TEST_LLR --llr_test_h0 $TEST_LLR_h0 --moments $MOMENTS_SUP --title "Supervised" --out_png $DIST_SUP --show_legend T
#Rscript Scripts/distribution.r --llr_test $TEST_LLR_H2_LDSC_CG --llr_test_h0 $TEST_LLR_H2_LDSC_CG_h0 --moments $MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG --title "Unsupervised" --out_png $DIST_UNSUP_H2_LDSC_CG_LDSC_CG --show_legend F
#
#mkdir -p $TMP/Dist_llr/
#cp $SCRATCH/$PARAM_FOLDER/Dist_llr/* $TMP/Dist_llr

#------------------------------------------------------------------------------#
# Compute precision and recall
#------------------------------------------------------------------------------#
Rscript Scripts/precision_recall.r --prob_h1_p $PROBA_SUP --prob_h0_p $PROBA_SUP_h0 --out_tsv $PRECREC_SUP
Rscript Scripts/precision_recall.r --prob_h1_p $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG --prob_h0_p $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_h0 --out_tsv $PRECREC_UNSUP_H2_LDSC_CG_LDSC_CG

#------------------------------------------------------------------------------#
# Export precision recall
#------------------------------------------------------------------------------#
mkdir -p $SCRATCH/Export/Precision_recall/

file_list=($PRECREC_SUP
	$PRECREC_UNSUP_H2_LDSC_CG_LDSC_CG)

export_list=($EXPORT_PRECREC_SUP
	$EXPORT_PRECREC_UNSUP_H2_LDSC_CG_LDSC_CG)

for idx in $(seq 0 $((${#file_list[@]}-1))); do
	cp ${file_list[$idx]} ${export_list[$idx]}
	echo ${export_list[$idx]}
done

#------------------------------------------------------------------------------#
# Export all necessay information
#------------------------------------------------------------------------------#

#cp -r $SCRATCH/Export/ $TMP
