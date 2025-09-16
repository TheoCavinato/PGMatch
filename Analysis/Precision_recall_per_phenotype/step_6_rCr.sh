

# Here we try to find a better metric than the number of phenotypes that would be linked to the number of phenotypes

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# dummy parameters (necessary but will should not affect result)
N_TEST=100000
N_TRAIN=1000
ITR=1
NBR_PHENO=40

# load variables
. .env

# create necessary directory
mkdir -p $DATA/Expectations/

#------------------------------------------------------------------------------#
# Compute expectations
#------------------------------------------------------------------------------#

Rscript  Scripts/rtCr.r --gen_cor_p $ORI_LDSC_CG \
	--gen_cov_p $ORI_LDSC_CV \
	--used_phenos_p $USED_PHENO \
	--out_p $EXPECTATIONS
