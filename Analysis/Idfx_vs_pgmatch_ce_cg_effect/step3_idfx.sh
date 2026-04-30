
#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# load parameters

. .env

CE_CG_FILE=$1
ITR=$2

. .env

mkdir -p $REAL_IDFX_FOLDER

#------------------------------------------------------------------------------#
# Transform created files to IDEFIX format
#------------------------------------------------------------------------------#

Rscript Scripts/my_format2idfx.r  \
	--pheno_test_p $PHENO_TEST \
	--pheno_train_p $PHENO_TRAIN \
	--pgs_test_p $PGS_TEST_H1 \
	--pgs_train_p $PGS_TRAIN_H1 \
	--out_pheno_test_idfx_p $PHENO_idfx_test \
	--out_pgs_test_idfx_p $PGS_idfx_test \
	--out_pheno_train_idfx_p $PHENO_idfx_train \
	--out_pgs_train_idfx_p $PGS_idfx_train \
	--out_mapping $MAPPING 

# validate data
echo "Next line should return only IID two times:"
comm -3 <(zcat $PHENO_idfx_test | awk '{print $1}' | sort) <(zcat $PGS_idfx_test | awk '{print $1}' | sort)
comm -3 <(zcat $PHENO_idfx_train | awk '{print $1}' | sort) <(zcat $PGS_idfx_train | awk '{print $1}' | sort)
comm -12 <(zcat $PHENO_idfx_test | awk '{print $1}' | sort) <(zcat $PHENO_idfx_train | awk '{print $1}' | sort)
comm -12 <(zcat $PGS_idfx_test | awk '{print $1}' | sort) <(zcat $PGS_idfx_train | awk '{print $1}' | sort)

echo "Next numbers should be the same:"
for FILE in $PGS_idfx_test $PGS_idfx_train $PHENO_idfx_test $PHENO_idfx_train; do
	zcat $FILE | wc -l
done

# prepare mapping
zcat $MAPPING |\
	awk 'BEGIN{print "trait\ttraitDataType\tsummaryStatistics"}
	NR>1{print $1,"\t",$2,"\t",""}' |\
	sed "s/numeric/continuous/g" > $SUB_MAPPING

# Create IDs we use for training
zcat $PHENO_TRAIN | awk 'BEGIN{print "geno\tpheno"}NR>1{printf $1"\t"$1"\n"}' > $IDS_TRAIN 

#------------------------------------------------------------------------------#
# Run IDEFIX - TRAINING
#------------------------------------------------------------------------------#

rm -rf $TRAIN_MODEL $TRAIN_MODEL_OUT
Rscript $IDEFIX_SWAP --phenotypes-file $PHENO_idfx_train \
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
Rscript $IDEFIX_SWAP --phenotypes-file $PHENO_idfx_test \
	--trait-gwas-mapping $SUB_MAPPING \
	--pgs-file $PGS_idfx_test \
	--p-expected-mixUps 0.5 \
	--base-fit-model-path $TRAIN_MODEL \
	--out $TEST_MODEL_OUT  

#------------------------------------------------------------------------------#
# Export it as a PROBA dataframe
#------------------------------------------------------------------------------#

training_ids_h1=$(zcat $PGS_TRAIN_H1 | awk 'NR>1{if(NR!=2) printf ","; printf $1}')
training_ids_h0=$(zcat $PGS_TRAIN_H0 | awk 'NR>1{if(NR!=2) printf ","; printf $1}')
Rscript Scripts/idfxLLRtoMyProba.r  --llr_idfx $TRAIN_MODEL_OUT/scaledLogLikelihoodRatiosMatrix.rds \
	--h0_iids $training_ids_h0 \
	--h1_iids $training_ids_h1 \
	--llr_h0 $REAL_IDFX_TRAIN_LLR_H0 \
	--llr_h1 $REAL_IDFX_TRAIN_LLR_H1

testing_ids_h1=$(zcat $PGS_TEST_H1 | awk 'NR>1{if(NR!=2) printf ","; printf $1}')
testing_ids_h0=$(zcat $PGS_TEST_H0 | awk 'NR>1{if(NR!=2) printf ","; printf $1}')
Rscript Scripts/idfxLLRtoMyProba.r  --llr_idfx $TEST_MODEL_OUT/scaledLogLikelihoodRatiosMatrix.rds \
	--h0_iids $testing_ids_h0 \
	--h1_iids $testing_ids_h1 \
	--llr_h0 $REAL_IDFX_TEST_LLR_H0 \
	--llr_h1 $REAL_IDFX_TEST_LLR_H1

#------------------------------------------------------------------------------#
# Compute proba with kde
#------------------------------------------------------------------------------#

Rscript $PGMATCH/llr2probas.r --llr_test $REAL_IDFX_TEST_LLR_H0 --llr_h0 $REAL_IDFX_TRAIN_LLR_H0 --llr_h1 $REAL_IDFX_TRAIN_LLR_H1 --round 10 --probas $REAL_IDFX_PROBAS_H0
Rscript $PGMATCH/llr2probas.r --llr_test $REAL_IDFX_TEST_LLR_H1 --llr_h0 $REAL_IDFX_TRAIN_LLR_H0 --llr_h1 $REAL_IDFX_TRAIN_LLR_H1 --round 10 --probas $REAL_IDFX_PROBAS_H1

concat_proba(){
awk 'BEGIN{OFS="\t"; print "proba","truth"}
	{print $2, (ARGIND==1 ? "H0" : "H1")}' <(zcat $1 | tail -n +2) <(zcat $2 | tail -n +2) |\
	gzip -c > $3
}

concat_proba $REAL_IDFX_PROBAS_H0 $REAL_IDFX_PROBAS_H1 $REAL_IDFX_PROBAS

