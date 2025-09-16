library(data.table)
library(argparse)

# rtCr might be a better way to quantify how much phenotypes help in the re-identification than just the number of phenotypes

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input data
parser$add_argument("--gen_cor_p", required=T)
parser$add_argument("--gen_cov_p", required=T)
parser$add_argument("--used_phenos_p", required=T)
# output data
parser$add_argument("--out_p", required=T)
args <- parser$parse_args()


# testing parameters
#gen_cor_p="/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/LDSC/LDSC_results/gen_s_stand.tsv"
#gen_cov_p="/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/LDSC/LDSC_results/gen_s.tsv"
#used_phenos_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_10.N_TEST_100000.N_TRAIN_1000/itr_1/Sort_phenos_by_var/phenos.txt"

#------------------------------------------------------------------------------#
# Import genetic correlation
#------------------------------------------------------------------------------#
gen_cor = as.matrix(read.table(args$gen_cor_p, hea=T, check.names=F))
stopifnot(colnames(gen_cor) == rownames(gen_cor))

gen_cov = as.matrix(read.table(args$gen_cov_p, hea=T, check.names=F))
stopifnot(colnames(gen_cor) == rownames(gen_cor))

pheno_df = fread(args$used_phenos_p)
names(pheno_df) = c("pheno_id", "r2", "n_males", "n_females", "name")

#------------------------------------------------------------------------------#
# Compute h2 * Corr " h2 (h2 scaled by genetic correlation)
#------------------------------------------------------------------------------#

cat("scaled_h2", "\t", "scaled_r2", "\t", "scaled_r", "\t", "sum_r2", "\t", "sum_h2", "\n",
	file=args$out_p)

for(n_pheno in c(2:nrow(pheno_df))) {
	used_phenos = as.character(pheno_df$pheno_id)[1:n_pheno]
	sub_gen_cor = as.matrix(gen_cor[used_phenos, used_phenos])
	sub_gen_cov = as.matrix(gen_cov[used_phenos, used_phenos])
	sub_gen_cor_inv = solve(sub_gen_cor)

	h2 = as.vector(diag(sub_gen_cov))
	r2 = pheno_df$r2[1:n_pheno]
	r = sqrt(r2)

	#scaled_h2 = h2 %*% sub_gen_cor %*% h2
	#scaled_r2 = r2 %*% sub_gen_cor %*% r2
	#scaled_r = r %*% sub_gen_cor %*% r

	scaled_h2 = h2 %*% sub_gen_cor_inv %*% h2
	scaled_r2 = r2 %*% sub_gen_cor_inv %*% r2
	scaled_r = r %*% sub_gen_cor_inv %*% r
	cat(scaled_h2, "\t", scaled_r2, "\t", scaled_r, "\t", sum(r2), "\t", sum(h2), "\n",
		file=args$out_p,
		append=T)
}
