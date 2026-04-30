
#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

CE_CG_FILE=$1
ITR=$2

. .env

mkdir -p $DATASET_FOLDER
#------------------------------------------------------------------------------#
# Create dataset
#------------------------------------------------------------------------------#

# get variance explained of the best X phenotypes
awk -v nbr_pheno=10 'BEGIN{print "r2"} NR>1 && NR<=(nbr_pheno+1){print $2}' $VAR_EXPL_NO_CORR > $R2_SIM

# create the datasets based on simulations
Rscript Scripts/create_dataset.r --r2 $R2_SIM \
	--pheno_train $PHENO_TRAIN \
	--pheno_test $PHENO_TEST \
	--pgs_test_h0 $PGS_TEST_H0 \
	--pgs_train_h0 $PGS_TRAIN_H0 \
	--pgs_test_h1 $PGS_TEST_H1 \
	--pgs_train_h1 $PGS_TRAIN_H1 \
	--ori_ce $CE_CG_FOLDER/$CE_CG_FILE.ce \
	--ori_cg $CE_CG_FOLDER/$CE_CG_FILE.cg \
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
