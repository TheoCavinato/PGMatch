#!/bin/bash
#SBATCH --job-name SortPhenotypes
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Compute_variance_explained/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Compute_variance_explained/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 4G
#SBATCH --time 00:20:00
#SBATCH --get-user-env=L
#SBATCH --export NONE

# Compute variance explained by phenotypes without sex stratification

module load r-light
source /work/FAC/FBM/DBC/amalaspi/popgen/tcavinat/PRS_attack_venv/prs_attack/bin/activate 

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# load variables
. .env

# make necessaries directories
mkdir -p $DATA/Scaled_phenotypes

#------------------------------------------------------------------------------#
# Compute the variance explained in the whole population
#------------------------------------------------------------------------------#

ls -1 $PGS_FOLDER  | sed "s/.*._//g" > $PHENOS_TO_PROCESS

:> $VAR_EXPL
while read PHENO; do
	. .env
	Rscript Scripts/re_compute_lr.r \
		--pheno_name $PHENO \
		--id_x_name_p $PHENOS \
		--caucasians_p $CAUCAS \
		--gwas_sample_p $GWAS_CAUCAS \
		--sex_p $SEX \
		--out_r2 $VAR_EXPL \
		--out_pheno $SCALED_PHENO
done < $PHENOS_TO_PROCESS

#------------------------------------------------------------------------------#
# Remove phenotypes with a low amount of individuals
#------------------------------------------------------------------------------#
awk -F '\t' '{
	if($3 > 100000 && $4 > 100000) {print}
}' $VAR_EXPL > $VAR_EXPL_MANY_INDS
	
#------------------------------------------------------------------------------#
# Remove correlated phenotypes i.e. when you have two correlated phenotypes
# remove the one with the lowest var expl
#------------------------------------------------------------------------------#

# Remove correlated phenotypes
Rscript Scripts/bad_phenotypes.r \
		--info_p $VAR_EXPL_MANY_INDS \
		--caucasians_p $CAUCAS \
		--gwas_sample_p $GWAS_CAUCAS \
		--sex_p $SEX \
		--out_r2 $VAR_EXPL_MANY_INDS_NO_CORR

