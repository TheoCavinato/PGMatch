#!/bin/bash
#SBATCH --job-name log10p2p
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/LDSC/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/LDSC/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 10G
#SBATCH --time 00:10:00
#SBATCH --get-user-env=L
#SBATCH --export NONE
#SBATCH --cpus-per-task=1

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# user parameters
PHENO=$1

# load variables
. .env

# create necessary output directories
mkdir -p $DATA/GWAS 

#------------------------------------------------------------------------------#
# Transform -log10p to p
#------------------------------------------------------------------------------#
Rscript Scripts/log10p2p.r --gwas_file $SUMSTAT \
	--out_new $REFORMAT_GWAS

