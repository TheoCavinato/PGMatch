
#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# load parameters

N_TEST=$1
N_TRAIN=$2
NBR_PHENO=$3
ITR=$4
. .env

mkdir -p $REAL_IDFX_FOLDER

#------------------------------------------------------------------------------#
# Transform created files to IDEFIX format
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
# Run IDEFIX - TRAINING
#------------------------------------------------------------------------------#

rm -rf $TRAIN_MODEL $TRAIN_MODEL_OUT
/usr/bin/time -v -o $TIME_IDFX_TRAIN Rscript $IDEFIX_SWAP --phenotypes-file $PHENO_idfx_train \
	--trait-gwas-mapping $SUB_MAPPING \
	--pgs-file $PGS_idfx_train \
	--sample-coupling-file $IDS_TRAIN \
	--p-expected-mixUps 0.0 \
	--base-fit-model-path $TRAIN_MODEL \
	--out $TRAIN_MODEL_OUT 

#------------------------------------------------------------------------------#
# Run IDEFIX - TESTING
#------------------------------------------------------------------------------#

rm -rf $TEST_MODEL_OUT
/usr/bin/time -v -o $TIME_IDFX_TEST Rscript $IDEFIX_SWAP --phenotypes-file $PHENO_idfx_test \
	--trait-gwas-mapping $SUB_MAPPING \
	--pgs-file $PGS_idfx_test \
	--p-expected-mixUps 0.5 \
	--base-fit-model-path $TRAIN_MODEL \
	--out $TEST_MODEL_OUT 

rm -r $REAL_IDFX_FOLDER
