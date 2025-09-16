#!/bin/bash
#SBATCH --job-name Idefix
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 40G
#SBATCH --time 01:20:00
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

# load parameters
. .env

# create necessary dierectories
mkdir -p $SCRATCH/$PARAM_FOLDER/Training $SCRATCH/$PARAM_FOLDER/Time $SCRATCH/$PARAM_FOLDER/Testing $SCRATCH/$PARAM_FOLDER/Moments $SCRATCH/$PARAM_FOLDER/LLR_idfx

#------------------------------------------------------------------------------#
# Subset the mapping depending on the number of phenotypes you want to use
#------------------------------------------------------------------------------#

zcat $MAPPING |
	awk 'BEGIN{print "trait\ttraitDataType\tsummaryStatistics"}
		NR>2{print $1,"\t",$2,"\t",""}' |\
	sed "s/numeric/continuous/g" |\
	sed "s/integer/ordinal/g" |\
	sed "s/PHENO_//g" |\
	head -n $((NBR_PHENO+1)) > $SUB_MAPPING

#------------------------------------------------------------------------------#
# Run IDEFIX - TRAINING
#------------------------------------------------------------------------------#

rm -rf $TRAIN_MODEL $TRAIN_MODEL_OUT
# i need to do this weird thing otherwise /usr/bin/time is sad
echo -e "module load r-light\nRscript $IDEFIX_SWAP --phenotypes-file $PHENO_idfx \
	--trait-gwas-mapping $SUB_MAPPING \
	--pgs-file $PGS_idfx \
	--sample-coupling-file $IDS_TRAIN \
	--p-expected-mixUps 0.0 \
	--base-fit-model-path $TRAIN_MODEL \
	--out $TRAIN_MODEL_OUT" > $SCRATCH/$PARAM_FOLDER/idefix.$NBR_PHENO.train.sh
/usr/bin/time -o $TIME_TRAINING -v bash  $SCRATCH/$PARAM_FOLDER/idefix.$NBR_PHENO.train.sh
rm $SCRATCH/$PARAM_FOLDER/idefix.$NBR_PHENO.train.sh

#------------------------------------------------------------------------------#
# Compute Moments
#------------------------------------------------------------------------------#

# modify data to compute moments
Rscript Scripts/idfx_dataset2me.r $TRAIN_MODEL_OUT/aggregatedLogLikelihoodRatiosMatrix.rds $PGS_train $PGS_train_h0 $LLR_H1 $LLR_H0

# compute moments
echo -e "\
module load r-light\n\
Rscript $PHENO_VS_PGS/moments_supervised.r --llr_h0 $LLR_H0 --llr_h1 $LLR_H1 --moments $SUB_MOMENTS_IDFX"\
 > $SCRATCH/$PARAM_FOLDER/moments.$NBR_PHENO.idfx.sh
/usr/bin/time -o $TIME_MOMENTS_IDFX -v bash $SCRATCH/$PARAM_FOLDER/moments.$NBR_PHENO.idfx.sh

#------------------------------------------------------------------------------#
# Run IDEFIX - TESTING
#------------------------------------------------------------------------------#

rm -rf $TEST_MODEL $TEST_MODEL_OUT
echo -e "module load r-light\nRscript $IDEFIX_SWAP --phenotypes-file $PHENO_idfx \
		--trait-gwas-mapping $SUB_MAPPING \
		--pgs-file $PGS_idfx \
		--sample-coupling-file $IDS_TEST \
		--p-expected-mixUps 0.5 \
		--base-fit-model-path $TRAIN_MODEL \
		--out $TEST_MODEL_OUT" > $SCRATCH/$PARAM_FOLDER/idefix.$NBR_PHENO.test.sh
/usr/bin/time -o $TIME_TESTING -v bash  $SCRATCH/$PARAM_FOLDER/idefix.$NBR_PHENO.test.sh
rm $SCRATCH/$PARAM_FOLDER/idefix.$NBR_PHENO.test.sh
