#!/bin/bash
#SBATCH --job-name munge
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/LDSC/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/LDSC/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 10G
#SBATCH --time 00:20:00
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
mkdir -p $DATA/Munge

#------------------------------------------------------------------------------#
# Run MUNGE
#------------------------------------------------------------------------------#
N=`zcat $REFORMAT_GWAS | head -n 2 | awk 'NR>1{print $NF}'`
Rscript Scripts/munge.r --out_dir $DATA/Munge \
	--gwas_files $REFORMAT_GWAS \
	--hm3 $HM3 \
	--trait_name $PHENO \
	--N $N
