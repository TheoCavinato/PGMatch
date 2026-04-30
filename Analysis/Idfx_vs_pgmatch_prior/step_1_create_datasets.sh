
#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# user parameters
NBR_PHENO=$1
N_TEST=$2
N_TRAIN=$3
ITR=$4

# load parameters
. .env 

# create directories if necessary
mkdir -p $SCRATCH/$PARAM_FOLDER/Sort_phenos_by_var/ $SCRATCH/$PARAM_FOLDER/Datasets/

#------------------------------------------------------------------------------#
# Create datasets
#------------------------------------------------------------------------------#
awk -F '\t' 'NR>1{ if($1 != 30180 ) {print}}' $VAR_EXPL_NO_CORR | head -n $NBR_PHENO > $USED_PHENO  # remove lymphocyte percentage (because we already have lymphocyte count)  
Rscript Scripts/create_datasets.r\
	--info_p $USED_PHENO\
	--n_test $N_TEST\
	--n_train $N_TRAIN\
	--caucasians_p $CAUCAS \
	--gwas_sample_p $GWAS_CAUCAS \
	--sex_p $SEX \
	--seed $ITR\
	--out_pheno_train $PHENO_train\
	--out_pgs_train $PGS_train\
	--out_pgs_train_h0 $PGS_train_h0\
	--out_pheno_test $PHENO_test\
	--out_pgs_test $PGS_test\
	--out_pgs_test_h0 $PGS_test_h0

