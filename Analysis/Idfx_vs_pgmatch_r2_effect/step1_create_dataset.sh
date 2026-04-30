
#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

R2_FILE=$1
ITR=$2

. .env

COR_MIN_CG=0.0
COR_MAX_CG=0.0
COR_MIN_CE=0.0
COR_MAX_CE=0.0

#------------------------------------------------------------------------------#
# Create dataset
#------------------------------------------------------------------------------#

mkdir -p $DATASET_FOLDER
# create the datasets based on simulations
Rscript Scripts/create_dataset.r --r2 $R2_FOLDER/$R2_FILE \
	--pheno_train $PHENO_TRAIN \
	--pheno_test $PHENO_TEST \
	--pgs_test_h0 $PGS_TEST_H0 \
	--pgs_train_h0 $PGS_TRAIN_H0 \
	--pgs_test_h1 $PGS_TEST_H1 \
	--pgs_train_h1 $PGS_TRAIN_H1 \
	--min_corr_ce $COR_MIN_CE \
	--max_corr_ce $COR_MAX_CE \
	--min_corr_cg $COR_MIN_CG \
	--max_corr_cg $COR_MAX_CG \
	--ce $CE_SIM \
	--cg $CG_SIM

# validate data
echo "Next line should return only IID two times:"
comm -3 <(zcat $PHENO_TEST | awk '{print $1}' | sort) <(zcat $PGS_TEST_H1 | awk '{print $1}' | sort)
comm -3 <(zcat $PHENO_TRAIN | awk '{print $1}' | sort) <(zcat $PGS_TRAIN_H1 | awk '{print $1}' | sort)
comm -12 <(zcat $PHENO_TEST | awk '{print $1}' | sort) <(zcat $PHENO_TRAIN | awk '{print $1}' | sort)
comm -12 <(zcat $PGS_TEST_H1 | awk '{print $1}' | sort) <(zcat $PGS_TRAIN_H1 | awk '{print $1}' | sort)

echo "Next numbers should be the same:"
for FILE in $PGS_TEST_H1 $PGS_TRAIN_H1 $PHENO_TEST $PHENO_TRAIN; do
	zcat $FILE | wc -l
done
