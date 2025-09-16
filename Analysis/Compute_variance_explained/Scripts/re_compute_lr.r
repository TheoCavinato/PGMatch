library(data.table)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--pheno_name", required=T)
parser$add_argument("--id_x_name_p", required=T)
parser$add_argument("--caucasians_p", required=T)
parser$add_argument("--gwas_sample_p", required=T)
parser$add_argument("--sex_p", required=T)

# ouptut
parser$add_argument("--out_r2", required=T)
parser$add_argument("--out_pheno", required=T)
args <- parser$parse_args()

## parameters for testing
#shared_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Shared_data/"
#args$pheno_name = 50
#args$id_x_name_p = paste0(shared_p,"phenotype_selection_for_GAM.txt")
#args$caucasians_p = paste0(shared_p,"UKB_caucasian.zk_ids.txt")
#args$gwas_sample_p = paste0(shared_p,"non_overlapping_caucasian_samples.txt")
#args$sex_p = paste0(shared_p,"UKB_sex.self_reported_and_genetic.txt")

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import name of the phenotype
id_x_name_df = read.table(args$id_x_name_p, sep="\t")
names(id_x_name_df) = c("pheno", "mod", "name")
name = id_x_name_df[id_x_name_df$pheno == args$pheno, ]$name

# Import GWAS samples
gwas_sample_df = na.omit(fread(args$gwas_sample_p, select=c(1))) # samples used in GWAS
names(gwas_sample_df) = c("IID")

# Import caucasians
ukb_caucasian = read.table(args$caucasians_p)
names(ukb_caucasian ) = c("IID")

# Import sex 
sex_df = na.omit(fread(args$sex_p, hea=T))
names(sex_df) = c("IID", "sex_reported", "sex_genetic")
sex_df = sex_df[sex_df$sex_reported == sex_df$sex_genetic, ]

# Import phenotypes 
get_pheno = function(pheno){
	PARAM="/data/FAC/FBM/DBC/zkutalik/default_sensitive/rhofmeis/data/UKBB/Phenotypes/data/phenotype_selection_for_GAM.txt"
	param_df = read.table(PARAM, hea=F, sep='\t')
	TYPE=param_df[param_df$V1 == pheno, ]$V2
	PHF=paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/rhofmeis/data/UKBB/Phenotypes/file_per_phecode/",TYPE,"/", pheno,".txt.gz")
	pheno_df = na.omit(fread(PHF, hea=T, select=c(2,3)))
	names(pheno_df) = c("IID", "PHENO")
	cat("Pheno", pheno, "imported with", nrow(pheno_df), "individuals with non-NA values.", "\n")
	if(TYPE=="mod_bt") {cat("Categories for trait:", unique(pheno_df$PHENO))}
	return(pheno_df)
}

# Import PGS
get_pgs = function(pheno){
	pgs_p=paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Compute_polygenic_scores/LDpred2_150K/PGS_calc/pheno_",pheno,"/score/aggregated_scores.txt.gz")
	pgs_df = na.omit(fread(pgs_p, hea=T, select=c(2,5))) #, select=c("iid", "pgsavg"))
	names(pgs_df) = c("IID", "PGS")
	cat("pgs ", pheno, "imported with", nrow(pgs_df), "individuals with non-na values.", "\n")
	return(pgs_df)
}

pheno_df = get_pheno(args$pheno)
pgs_df = get_pgs(args$pheno)

#------------------------------------------------------------------------------#
# Transform it into a sex corrected pgs
#------------------------------------------------------------------------------#

# Filter non-caucasian individuals and find overlapping samples between datasets
matched_samples = intersect(pgs_df$IID, pheno_df$IID) # overlap between df
cat("Keep overlaping samples:", length(matched_samples), "individuals left\n")
matched_samples = intersect(matched_samples, ukb_caucasian$IID) # only keep caucasians
cat("Filter out non caucasians:", length(matched_samples), "individuals left\n")
matched_samples = setdiff(matched_samples, gwas_sample_df$IID) # remove gwas samples
cat("Filter out gwas samples:", length(matched_samples), "individuals left\n")
matched_samples = intersect(matched_samples, sex_df$IID) # remove gwas samples
cat("Only keep the ones for which we know the sex:", length(matched_samples), "individuals left\n")

id_pgs = match(matched_samples, pgs_df$IID)
id_pheno = match(matched_samples, pheno_df$IID)
id_sex = match(matched_samples, sex_df$IID)
pgs_df = pgs_df[id_pgs, ]
pheno_df = pheno_df[id_pheno, ]
sex_df = sex_df[id_sex, ]
stopifnot(identical(pheno_df$IID, pgs_df$IID))
stopifnot(identical(pheno_df$IID, sex_df$IID))

merge_df = data.table(IID=pheno_df$IID,
	PHENO = pheno_df$PHENO,
	PGS=pgs_df$PGS,
	SEX=sex_df$sex_genetic)

#------------------------------------------------------------------------------#
# Correct pgs for sex
#------------------------------------------------------------------------------#

# Mean height in males and females
mean_males = mean(merge_df[merge_df$SEX==1, ]$PHENO)
mean_females = mean(merge_df[merge_df$SEX==0, ]$PHENO)
pheno_diff = mean_males - mean_females

# Correct the pheno
merge_df$PHENO_SCALED = scale(merge_df$PHENO - pheno_diff*merge_df$SEX)

# Look at the variance explained
var_expl = cor(merge_df$PHENO_SCALED, merge_df$PGS, use = "pairwise.complete.obs", method="pearson")^2

#------------------------------------------------------------------------------#
# Output information
#------------------------------------------------------------------------------#
# write variance explained
n_males = sum(merge_df$SEX)
n_females = nrow(merge_df) - n_males
cat(args$pheno, "\t",
	var_expl, "\t",
	n_males, "\t",
	n_females, "\t",
	name, "\n",
	file=args$out_r2, append=T)

# write phenotype corrected for sex
gz_out = gzfile(args$out_pheno, "w")
write.table(merge_df, file=gz_out, quote=F, sep='\t', row.names=F)
close(gz_out)


