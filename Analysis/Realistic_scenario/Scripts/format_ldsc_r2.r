library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--r2", required=T)
parser$add_argument("--ori_ldsc_cg", required=T)
parser$add_argument("--ori_ldsc_cv", required=T)
# output
parser$add_argument("--h2", required=T)
parser$add_argument("--ldsc_cg", required=T)
args <- parser$parse_args()

# debugging
#args$r2 = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_infer_phenotypes/Analysis.NBR_PHENO_10.N_TEST_10.N_TRAIN_10.TARGET_50/Correlations/r2.tsv.gz"
#args$ori_ldsc_cg="/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/LDSC/GenCor/gen_cor.tsv"
#args$ori_ldsc_cv="/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/LDSC/GenCor/gen_cov.correct_rownames.tsv"
#
#args$h2 = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_infer_phenotypes/Analysis.NBR_PHENO_10.N_TEST_10.N_TRAIN_10.TARGET_50/Correlations/h2.tsv.gz"
#args$ldsc_cg = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_infer_phenotypes/Analysis.NBR_PHENO_10.N_TEST_10.N_TRAIN_10.TARGET_50/Correlations/ldsc_cg.tsv.gz"

#------------------------------------------------------------------------------#
# Modifiy data
#------------------------------------------------------------------------------#

# get phenotypes of interest
r2_df = read.table(args$r2, hea=T)
phenos = sub("PHENO_", "", r2_df$pheno)

# import ldsc cor and cov
ori_ldsc_cg = read.table(args$ori_ldsc_cg, hea=T, check.names=F)
ori_ldsc_cv = read.table(args$ori_ldsc_cv, hea=T, check.names=F)
stopifnot(colnames(ori_ldsc_cv) == colnames(ori_ldsc_cg))
stopifnot(colnames(ori_ldsc_cv) == rownames(ori_ldsc_cv))

# get heritability of phenotypes
h2 = diag(as.matrix(ori_ldsc_cv[phenos, phenos]))

# subsample ldsc cg
ldsc_cg = ori_ldsc_cg[phenos, phenos]

#------------------------------------------------------------------------------#
# Write output
#------------------------------------------------------------------------------#

out_gz = gzfile(args$h2, 'w')
h2_df = data.frame(pheno=r2_df$pheno, r2=h2)
write.table(h2_df, file=out_gz, row.names=F, quote=F, sep='\t')
close(out_gz)

out_gz = gzfile(args$ldsc_cg, 'w')
write.table(ldsc_cg, file=out_gz, row.names=F, quote=F, col.names=F, sep='\t')
close(out_gz)
