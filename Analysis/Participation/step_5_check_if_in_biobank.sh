#!/bin/bash
#SBATCH --job-name SumProbabilities
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 1G
#SBATCH --time 00:10:00
#SBATCH --cpus-per-task 3
#SBATCH --get-user-env=L
#SBATCH --export NONE

# Can we tell if someone is in the biobank?
#maybe by summing over all the probabilities in the datasert
#if a test need to be benchmark here, it should be on a probability
#that takes into the proba of being part of the UKB

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

# load variables
. .env

# make necessary directories
mkdir -p $DATA/Participation_checking

#------------------------------------------------------------------------------#
# Analyse presence or absence
#------------------------------------------------------------------------------#

PREFIX_LIST=("$PREFIX_PROBA_SUP_target" "$PREFIX_PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_target")
TSV_LIST=("$TSV_SUP_PARTICIPATION" "$TSV_UNSUP_H2_LDSC_CG_LDSC_CG_PARTICIPATION")
#
#for i in "${!PREFIX_LIST[@]}"; do
#	Rscript Scripts/check_if_in_biobank.r --pgs_p $PGS_test \
#		--prefix_proba ${PREFIX_LIST[$i]} \
#		--suffix ".tsv.gz" \
#		--biobank_size $BIOBANK_SIZE \
#		--out_tsv ${TSV_LIST[$i]} &
#done
#wait
#
#echo "Distribution computed!"

#------------------------------------------------------------------------------#
# Plot the distributions
#------------------------------------------------------------------------------#

PDF_LIST_SUM=($PDF_SUP_PARTICIPATION_SUM $PDF_UNSUP_H2_LDSC_CG_LDSC_CG_PARTICIPATION_SUM)
PDF_LIST_MAX=($PDF_SUP_PARTICIPATION_MAX $PDF_UNSUP_H2_LDSC_CG_LDSC_CG_PARTICIPATION_MAX)
PDF_LIST=($PDF_SUP_PARTICIPATION $PDF_UNSUP_H2_LDSC_CG_LDSC_CG_PARTICIPATION)
for i in "${!TSV_LIST[@]}"; do
	Rscript Scripts/plot_participation.r --participation_p ${TSV_LIST[$i]} \
		--biobank_size $BIOBANK_SIZE \
		--pdf_out ${PDF_LIST[$i]} &
		#--pdf_sum ${PDF_LIST_SUM[$i]} \
		#--pdf_max ${PDF_LIST_MAX[$i]} &
done
wait
echo "Plotting done!"

for PDF in "${PDF_LIST[@]}"; do
	cp $PDF $TMP
done

