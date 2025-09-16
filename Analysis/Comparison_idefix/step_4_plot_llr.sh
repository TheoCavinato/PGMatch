#!/bin/bash
#SBATCH --job-name TSVprecrec
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

NBR_PHENO=$1
N_TEST=$2
N_TRAIN=$3

. .env

SCRATCH=/scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix

# create necessary directories
mkdir -p $SCRATCH/$PARAM_FOLDER/TSV_precrec/

#------------------------------------------------------------------------------#
# Run
#------------------------------------------------------------------------------#

Rscript Scripts/precision_recall.r \
	--me_h1_p $TRAIN_LLR \
	--me_h0_p $TRAIN_LLR_H0 \
	--idfx_p $TRAIN_MODEL_OUT/aggregatedLogLikelihoodRatiosMatrix.rds \
	--mom_me_p $SUB_MOMENTS \
	--mom_idfx_p $SUB_MOMENTS_IDFX  \
	--me_tsv $TSV_ME_PREC_REC \
	--idfx_tsv $TSV_IDFX_PREC_REC
