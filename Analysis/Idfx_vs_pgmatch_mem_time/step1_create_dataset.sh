
#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

N_TEST=$1
N_TRAIN=$2
NBR_PHENO=$3
. .env

#------------------------------------------------------------------------------#
# Create dataset
#------------------------------------------------------------------------------#

mkdir -p $DATASET_FOLDER
# create the datasets based on simulations
Rscript Scripts/create_dataset.r --n_pheno $NBR_PHENO \
	--n_train $N_TRAIN \
	--n_test $N_TEST \
	--pheno_train $PHENO_TRAIN \
	--pheno_test $PHENO_TEST \
	--pgs_test_h0 $PGS_TEST_H0 \
	--pgs_train_h0 $PGS_TRAIN_H0 \
	--pgs_test_h1 $PGS_TEST_H1 \
	--pgs_train_h1 $PGS_TRAIN_H1 


#------------------------------------------------------------------------------#
# Convert to idfx format
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

# prepare mapping
zcat $MAPPING |\
	awk 'BEGIN{print "trait\ttraitDataType\tsummaryStatistics"}
	NR>1{print $1,"\t",$2,"\t",""}' |\
	sed "s/numeric/continuous/g" > $SUB_MAPPING

# Create IDs we use for training
zcat $PHENO_TRAIN | awk 'BEGIN{print "geno\tpheno"}NR>1{printf $1"\t"$1"\n"}' > $IDS_TRAIN 

#------------------------------------------------------------------------------#
# Validations
#------------------------------------------------------------------------------#

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


