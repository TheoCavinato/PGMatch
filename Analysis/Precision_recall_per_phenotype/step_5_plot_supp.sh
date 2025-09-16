
module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#
# user parameters
N_TEST=100000
N_TRAIN=1000
ITR=1

. .env

# ouptut
PARAMETERS_SUP=$SCRATCH/Export/parameters_sup.tsv
PARAMETERS_UNSUP=$SCRATCH/Export/parameters_unsup.tsv
SUP_PDF=$SCRATCH/Export/merge_sup.pdf
UNSUP_PDF=$SCRATCH/Export/merge_unsup.pdf

#------------------------------------------------------------------------------#
# Prepare data
#------------------------------------------------------------------------------#
echo -e nbr_pheno"\t"test_llr_h1"\t"test_llr_h0"\t"moments_p > $PARAMETERS_SUP
echo -e nbr_pheno"\t"test_llr_h1"\t"test_llr_h0"\t"moments_p > $PARAMETERS_UNSUP
for NBR_PHENO in 5 10 20 30 40; do
	. .env
	echo -e $NBR_PHENO"\t"$TEST_LLR"\t"$TEST_LLR_h0"\t"$MOMENTS_SUP  >> $PARAMETERS_SUP
	echo -e $NBR_PHENO"\t"$TEST_LLR_H2_LDSC_CG"\t"$TEST_LLR_H2_LDSC_CG_h0"\t"$MOMENTS_UNSUP_H2_LDSC_CG_LDSC_CG >> $PARAMETERS_UNSUP 
done
Rscript Scripts/distribution.all.r --parameters $PARAMETERS_SUP --out_pdf $SUP_PDF
Rscript Scripts/distribution.all.r --parameters $PARAMETERS_UNSUP --out_pdf $UNSUP_PDF
