

# Extract information for plots
# The goal is to answer two questions:
# * what was the LLR values of the target individual, and how do they compare to the rest of the individuals
# * how many individuals were above the LLR threshold of a target and is match

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#
# user parameteres
NBR_PHENO=$1
N_TEST=$2
N_TRAIN=$3
SEED=$4

# load variables
. .env

# create necessary directrories
mkdir -p $DATA/Final_results/

#------------------------------------------------------------------------------#
# Run extraction
#------------------------------------------------------------------------------#

#PREF_PROB_LIST=(PREFIX_PROBA_SUP_target PREFIX_PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_target)
#PREF_LLR_LIST=(PREFIX_TEST_LLR_target PREFIX_TEST_LLR_H2_LDSC_CG_target)
#TSV_LIST=(TSV_SUP_RESULT TSV_UNSUP_H2_LDSC_CG_LDSC_CG)
echo "Supervised calculation"
Rscript Scripts/extract.r --pgs_p $PGS_test \
	--prefix_proba $PREFIX_PROBA_SUP_target \
	--prefix_llr $PREFIX_TEST_LLR_target \
	--suffix ".tsv.gz" \
	--out_tsv $TSV_SUP_RESULT &

echo "Unsupervised calculation"
Rscript Scripts/extract.r --pgs_p $PGS_test \
	--prefix_proba $PREFIX_PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_target \
	--prefix_llr $PREFIX_TEST_LLR_H2_LDSC_CG_target \
	--suffix ".tsv.gz" \
	--out_tsv $TSV_UNSUP_H2_LDSC_CG_LDSC_CG &

echo "Supervised calculation optimus"
Rscript Scripts/extract.r --pgs_p $PGS_test \
	--prefix_proba $PREFIX_PROBA_SUP_target \
	--prefix_llr $PREFIX_TEST_LLR_target \
	--suffix ".optimus.tsv.gz" \
	--out_tsv $TSV_SUP_RESULT_optimus &

echo "Unsupervised calculation optimus"
Rscript Scripts/extract.r --pgs_p $PGS_test \
	--prefix_proba $PREFIX_PROBA_UNSUP_H2_LDSC_CG_LDSC_CG_target \
	--prefix_llr $PREFIX_TEST_LLR_H2_LDSC_CG_target \
	--suffix ".optimus.tsv.gz" \
	--out_tsv $TSV_UNSUP_H2_LDSC_CG_LDSC_CG_optimus &

wait 

#------------------------------------------------------------------------------#
# Copy to tmp for ease of sftp transfer
#------------------------------------------------------------------------------#

cp $TSV_SUP_RESULT $TMP/
cp $TSV_UNSUP_H2_LDSC_CG_LDSC_CG $TMP/
cp $TSV_SUP_RESULT_optimus $TMP/
cp $TSV_UNSUP_H2_LDSC_CG_LDSC_CG_optimus $TMP/
