library(data.table)
library(reshape2)
library(argparse)

# Some phenotypes are breaking the distirbution of Unsup and Sup
# One explanation might be that they can already be explained by all the other
# phenotypes used. To validate this, we run linear regression between each of the phenotypes

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--info_p", required=T)
parser$add_argument("--caucasians_p", required=T)
parser$add_argument("--gwas_sample_p", required=T)
parser$add_argument("--sex_p", required=T)
# ouptut
parser$add_argument("--out_r2", required=T)

args = parser$parse_args()

# parameters for testing
shared_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Shared_data/"
args$info_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Compute_variance_explained/variance_explained.many_inds.tsv"
args$id_x_name_p = paste0(shared_p,"phenotype_selection_for_GAM.txt")
args$caucasians_p = paste0(shared_p,"UKB_caucasian.zk_ids.txt")
args$gwas_sample_p = paste0(shared_p,"non_overlapping_caucasian_samples.txt")
args$sex_p = paste0(shared_p,"UKB_sex.self_reported_and_genetic.txt")

#------------------------------------------------------------------------------#
# Import phenotypes
#------------------------------------------------------------------------------#
sorted_df = fread(args$info_p, sep='\t', col.names=c("pheno", "r2", "males_nbr", "females_nbr", "name"))
sorted_df = sorted_df[order(-sorted_df$r2),]
phenos = sorted_df$pheno

# Import GWAS samples
gwas_sample_df = na.omit(fread(args$gwas_sample_p, select=c(1))) # samples used in GWAS
names(gwas_sample_df) = c("IID")

# Import caucasians
ukb_caucasian = read.table(args$caucasians_p)
names(ukb_caucasian ) = c("IID")

# Import sex
sex_df = na.omit(read.table(args$sex_p, hea=T))
names(sex_df) = c("IID", "sex_reported", "sex_genetic")
sex_df = sex_df[sex_df$sex_reported == sex_df$sex_genetic, ]

# Import phenotypes
get_pheno = function(pheno){
	pheno_folder = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Compute_variance_explained/Scaled_phenotypes/pheno_"
	PHF = paste0(pheno_folder, pheno, ".tsv.gz")
	pheno_df = na.omit(fread(PHF, hea=T, select=c(1,2)))
	names(pheno_df) = c("IID", paste0("PHENO_", pheno))
	cat("Pheno", pheno, "imported with", nrow(pheno_df), "individuals with non-NA values.", "\n")
	return(pheno_df)
}

merged_pheno_df = NULL 

for(pheno in phenos){
	pheno_df = get_pheno(pheno)
	if(pheno == phenos[1]) {merged_pheno_df = pheno_df}
	else {merged_pheno_df = merge(merged_pheno_df, pheno_df, by="IID")}
	cat(nrow(merged_pheno_df), "people remaining...", "\n")
}

# Filter non-caucasian individuals and find overlapping samples between datasets
matched_samples = intersect(merged_pheno_df$IID, ukb_caucasian$IID) # only gwas caucasians
cat("Filter out non caucasians:", length(matched_samples), "individuals left\n")
matched_samples = setdiff(matched_samples, gwas_sample_df$IID) # remove gwas samples
cat("Filter out gwas samples:", length(matched_samples), "individuals left\n")

id_pheno = match(matched_samples, merged_pheno_df$IID)
merged_pheno_df = merged_pheno_df[id_pheno, ]

# remove IID
merged_pheno_df = merged_pheno_df[, -1]

#------------------------------------------------------------------------------#
# Make the linear regression
#------------------------------------------------------------------------------#

cor_mat = cor(merged_pheno_df)
# start with the phenotypes with the lowest variance explained,
#look if there is a phenotype with a higher variance explained correlated to him
#if so, remove the phenotype
# repeat

good_phenos = c()
for(idx in c(ncol(cor_mat):2)){
	line = as.vector(cor_mat[idx,c(1:(idx-1))])
	best_cor = max(line)
	if(best_cor < 0.8) { good_phenos = c(good_phenos, phenos[idx]) }
}
good_phenos = c(good_phenos, phenos[1])

new_sorted_df = sorted_df[sorted_df$pheno %in% good_phenos, ]
write.table(new_sorted_df, file=args$out_r2, row.names=F, sep='\t')
cat("Keep:", length(good_phenos), "phenotypes\n")

#------------------------------------------------------------------------------#
# Validation: make sure none of the resulting phenotypes are correlated
#------------------------------------------------------------------------------#

new_cols = paste0("PHENO_", good_phenos)
new_merged_pheno_df = merged_pheno_df[, ..new_cols]
cor_mat = cor(new_merged_pheno_df)
diag(cor_mat) = 0
stopifnot(max(cor_mat) < 0.8)
