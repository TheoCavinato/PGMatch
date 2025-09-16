#!/bin/bash
#SBATCH --job-name PrecRecAndExport
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 10G
#SBATCH --cpus-per-task 3
#SBATCH --time 00:20:00
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
BIOBANK_SIZE=$5

# load parameters
. .env 

# create directories if necessary
mkdir -p $SCRATCH/$PARAM_FOLDER/Precision_recall
mkdir -p $SCRATCH/$PARAM_FOLDER/Dist_llr/
mkdir -p $TMP/Precision_recall_realistic_scenario

#------------------------------------------------------------------------------#
# Compute precision and recall
#------------------------------------------------------------------------------#
Rscript Scripts/precision_recall.r --prob_h1_p $PROBA_SUP --prob_h0_prefix $PROBA_SUP_h0_wheeled_prefix --biobank_size $BIOBANK_SIZE --out_tsv $PRECREC_SUP &
Rscript Scripts/precision_recall.r --prob_h1_p $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG --prob_h0_p $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_h0_wheeled_prefix --biobank_size $BIOBANK_SIZE --out_tsv $PRECREC_UNSUP_H2_LDSC_CG_LDSC_CG &

wait
echo "Computation done!"
cp $PRECREC_SUP $TMP/Precision_recall_realistic_scenario/
cp $PRECREC_UNSUP_H2_LDSC_CG_LDSC_CG $TMP/Precision_recall_realistic_scenario/
