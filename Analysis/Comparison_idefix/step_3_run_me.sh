#!/bin/bash
#SBATCH --job-name Assurancetourix
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

# load parameters
. .env

# output
mkdir -p $SCRATCH/$PARAM_FOLDER/SubDataset $SCRATCH/$PARAM_FOLDER/Correlations $SCRATCH/$PARAM_FOLDER/LLR_me $SCRATCH/$PARAM_FOLDER/Time $SCRATCH/$PARAM_FOLDER/Moments

#------------------------------------------------------------------------------#
# Prepare dataset
#------------------------------------------------------------------------------#

for FILE_P in $PHENO_10K $PGS_10K $PHENO_train $PGS_train $PGS_train_h0 $PGS_test $PGS_test_h0 $PHENO_test; do

	SUB_P=`echo $FILE_P | sed "s/Datasets/SubDataset/g" |\
		sed "s/pgs/${NBR_PHENO}_cols.pgs/g" |\
		sed "s/pheno/${NBR_PHENO}_cols.pheno/g"`
	zcat $FILE_P | awk -v N=$((NBR_PHENO+1)) '{
	    for (i = 1; i <= N && i <= NF; i++) {
		printf "%s%s", $i, (i < N && i < NF ? OFS : ORS)
	    }
	}' | gzip -c > $SUB_P
done

#------------------------------------------------------------------------------#
# 1. Compute Ce, Cg and r2 on 10K individuals (represent valus we would know from another dataset)
#------------------------------------------------------------------------------#


# supervised model
# i need to do this weird echo otherwise /usr/bin/time is sad
echo -e "\
module load r-light\n\
Rscript $PHENO_VS_PGS/compute_ce_cg_r2.r --pgs $SUB_PGS_10K --pheno $SUB_PHENO_10K --r2 $R2 --ce $CE --cg $CG"\
> $SCRATCH/$PARAM_FOLDER/learning.$NBR_PHENO.sh
/usr/bin/time -v -o $TIME_L bash $SCRATCH/$PARAM_FOLDER/learning.$NBR_PHENO.sh

# unsupervised model
Rscript Scripts/format_ldsc_r2.r --r2 $R2 --ori_ldsc_cg $ORI_LDSC_CG --ori_ldsc_cv $ORI_LDSC_CV --h2 $LDSC_H2 --ldsc_cg $LDSC_CG

#------------------------------------------------------------------------------#
# 2. Compute LLR on training set (represent a subset of individuals we have access to)
#------------------------------------------------------------------------------#

# supervised model
echo -e "\
module load r-light\n\
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $SUB_PGS_TRAIN --pheno $SUB_PHENO_TRAIN --r2 $R2 --ce $CE --llr $TRAIN_LLR"\
> $SCRATCH/$PARAM_FOLDER/training.h1.$NBR_PHENO.sh
/usr/bin/time -v -o $TIME_H1 bash $SCRATCH/$PARAM_FOLDER/training.h1.$NBR_PHENO.sh

echo -e "\
module load r-light\n\
Rscript $PHENO_VS_PGS/llr_computation.r --pgs $SUB_PGS_TRAIN_h0 --pheno $SUB_PHENO_TRAIN --r2 $R2 --ce $CE --llr $TRAIN_LLR_H0"\
> $SCRATCH/$PARAM_FOLDER/training.h0.$NBR_PHENO.sh
/usr/bin/time -v -o $TIME_H0 bash $SCRATCH/$PARAM_FOLDER/training.h0.$NBR_PHENO.sh

##------------------------------------------------------------------------------#
## 3. Get moments
##------------------------------------------------------------------------------#
#
## supervised model
#echo -e "\
#module load r-light\n\
#Rscript $PHENO_VS_PGS/moments_supervised.r --llr_h0 $TRAIN_LLR_H0 --llr_h1 $TRAIN_LLR --moments $SUB_MOMENTS"\
# > $SCRATCH/$PARAM_FOLDER/moments.$NBR_PHENO.sh
#/usr/bin/time -v -o $TIME_MOMENTS_ME bash $SCRATCH/$PARAM_FOLDER/moments.$NBR_PHENO.sh
#
## unsupervised model
#Rscript $PHENO_VS_PGS/moments_unsupervised.r --r2 $LDSC_H2 --ce $LDSC_CG --cg $LDSC_CG --moments $SUB_MOMENTS_UNSUP
#
##------------------------------------------------------------------------------#
## 4. Compute LLR on testing set (respresent the individuals we are interested in)
##------------------------------------------------------------------------------#
#
## supervised model
#echo -e "\
#module load r-light\n\
#Rscript $PHENO_VS_PGS/llr_computation.r --pgs $SUB_PGS_TEST --pheno $SUB_PHENO_TEST --r2 $R2 --ce $CE --llr $TEST_LLR"\
# > $SCRATCH/$PARAM_FOLDER/testing.$NBR_PHENO.sh
##/usr/bin/time -v -o $TIME_MOMENTS bash $SCRATCH/$PARAM_FOLDER/testing.$NBR_PHENO.sh
#
#echo -e "\
#module load r-light\n\
#Rscript $PHENO_VS_PGS/llr_computation.r --pgs $SUB_PGS_TEST_h0 --pheno $SUB_PHENO_TEST --r2 $R2 --ce $CE --llr $TEST_LLR_H0"\
# > $SCRATCH/$PARAM_FOLDER/testing.$NBR_PHENO.h0.sh
##/usr/bin/time -v -o $TIME_MOMENTS bash $SCRATCH/$PARAM_FOLDER/testing.$NBR_PHENO.h0.sh
#
## unsupervised model
#Rscript $PHENO_VS_PGS/llr_computation.r --pgs $SUB_PGS_TEST --pheno $SUB_PHENO_TEST --r2 $LDSC_H2 --ce $LDSC_CG --llr $TEST_LLR_UNSUP
#Rscript $PHENO_VS_PGS/llr_computation.r --pgs $SUB_PGS_TEST_h0 --pheno $SUB_PHENO_TEST --r2 $LDSC_H2 --ce $LDSC_CG --llr $TEST_LLR_H0_UNSUP
#
