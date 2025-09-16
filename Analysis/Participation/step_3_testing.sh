#!/bin/bash
#SBATCH --job-name Testing
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 40G
#SBATCH --time 00:50:00
#SBATCH --cpus-per-task 41
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light

# I need to compute the similarity beteween one individual and the rest of the pgs
#to do so, I need to take one row of the phenotype test dataset, and replicate it
#X times to create the input phenotype dataset
#this would mean this step is parallelized across the targets

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#
# user parameters
NBR_PHENO=$1
N_TEST=$2
N_TRAIN=$3
SEED=$4

# load parameters
. .env 

# create directories if necessary
mkdir -p  $SCRATCH/$PARAM_FOLDER/Datasets_subsampled/ $SCRATCH/$PARAM_FOLDER/LLR_computed $SCRATCH/$PARAM_FOLDER/Probas

#------------------------------------------------------------------------------#
# Compute LLR between every match. This will allow us to study the best 
#performing one in more details
#------------------------------------------------------------------------------#

Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $R2 --ce $CE --llr $TEST_LLR --qnorm F

# get ids of the best performing
zcat $TEST_LLR  | tail -n +2 | sort -nk2 | tac | head -n 1000 | awk '{print $1}' > $OPTIMUS_PEOPLE

#------------------------------------------------------------------------------#
# 1. Create the subsampling dataset
#------------------------------------------------------------------------------#

export NBR_PHENO N_TEST N_TRAIN SEED
echo "Creating the files for random people..."
seq 1 1000 | xargs -n 1 -P 40 bash -c '
	TARGET_IDX=$1
	. .env
	zcat $PHENO_test | head -n 1 | gzip -c > $PHENO_test_target # write header
	TARGET_LINE=$(zcat $PHENO_test | tail -n +2 | head -n $TARGET_IDX | tail -1)
	yes "$TARGET_LINE" | head -n $N_TEST | gzip -c >> $PHENO_test_target
' _

echo "Creating the files for the people with the highest LLR..."
seq 1 1000 | xargs -n 1 -P 40 bash -c '
	TARGET_IDX=$1
	. .env
	SAMPLE_ID=$(head -n $TARGET_IDX $OPTIMUS_PEOPLE | tail -1)
	TARGET_LINE=$(zcat $PHENO_test | awk -v SAMPLE_ID=$SAMPLE_ID '\''NR>1{if($1==SAMPLE_ID) {print; exit}}'\'')
	zcat $PHENO_test | head -n 1 | gzip -c > $PHENO_test_target_optimus # write header
	yes "$TARGET_LINE" | head -n $N_TEST | gzip -c >> $PHENO_test_target_optimus
' _

#------------------------------------------------------------------------------#
# 1. Compute LLR on testing set (respresent the individuals we are interested in)
#------------------------------------------------------------------------------#

echo "Making the LLR computation for random people..."
seq 1 1000 | xargs -n 1 -P 40 bash -c '
	module load r-light
	TARGET_IDX=$1
	. .env
	# classic (r2 ce)
	Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test_target --r2 $R2 --ce $CE --llr $TEST_LLR_target --qnorm F
	# h2, ldsc_cg
	Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test_target --r2 $LDSC_H2 --ce $LDSC_CG --llr $TEST_LLR_H2_LDSC_CG_target --qnorm F
' _

echo "Making the LLR computation for the people with the highest llr..."
seq 1 1000 | xargs -n 1 -P 40 bash -c '
	module load r-light
	TARGET_IDX=$1
	. .env
	# classic (r2 ce)
	Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test_target_optimus --r2 $R2 --ce $CE --llr $TEST_LLR_target_optimus --qnorm F
	# h2, ldsc_cg
	Rscript $PHENO_VS_PGS/llr_computation.r --pgs $PGS_test --pheno $PHENO_test_target_optimus --r2 $LDSC_H2 --ce $LDSC_CG --llr $TEST_LLR_H2_LDSC_CG_target_optimus --qnorm F
' _
	
#------------------------------------------------------------------------------#
# 2. Compute probabilities on testing set
#------------------------------------------------------------------------------#

echo "Making the probabilities computation for randome people..."
seq 1 1000 | xargs -n 4 -P 40 bash -c '
	module load r-light
	TARGET_IDX=$1
	. .env
	# supervised
	Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_target --moments $MOMENTS_SUP --probas $PROBA_SUP_target --round 10
	# unsupervised h2, ldsc cg, ldsc cg
	Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_H2_LDSC_CG_target --moments $MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG --probas $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_target --round 10
' _
       
echo "Making the probabilities computation for people with the highest LLR..."
seq 1 1000 | xargs -n 1 -P 40 bash -c '
	module load r-light
	TARGET_IDX=$1
	. .env
	# supervised
	Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_target_optimus --moments $MOMENTS_SUP --probas $PROBA_SUP_target_optimus --round 10
	# unsupervised h2, ldsc cg, ldsc cg
	Rscript $PHENO_VS_PGS/llr2probas.r --llr $TEST_LLR_H2_LDSC_CG_target_optimus --moments $MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG --probas $PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_target_optimus --round 10
' _
       

