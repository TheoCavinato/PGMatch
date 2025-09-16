suppressPackageStartupMessages(library(R.utils))
library(data.table)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser
parser <- ArgumentParser()
# input
parser$add_argument("--info_p", required=T)
parser$add_argument("--n_train", required=T, type="integer")
parser$add_argument("--n_test", required=T, type="integer")
parser$add_argument("--seed", required=T, type="integer")
parser$add_argument("--caucasians_p", required=T)
parser$add_argument("--gwas_sample_p", required=T)
parser$add_argument("--sex_p", required=T)
parser$add_argument("--cov_p", required=T)

# output
parser$add_argument("--out_pheno_10K", required=T)
parser$add_argument("--out_pgs_10K", required=T)
parser$add_argument("--out_pheno_train", required=T)
parser$add_argument("--out_pgs_train", required=T)
parser$add_argument("--out_pgs_train_h0", required=T)
parser$add_argument("--out_pheno_test", required=T)
parser$add_argument("--out_pgs_test", required=T)
parser$add_argument("--out_pgs_test_h0", required=T)

parser$add_argument("--out_pheno_idfx", required=T)
parser$add_argument("--out_pgs_idfx", required=T)
parser$add_argument("--out_mapping", required=T)
args <- parser$parse_args()

# set seed (so that every iteration uses different individuals, but all the iteration with the same number across all parameters are based on the same individuals)
set.seed(args$seed)

## parameters for training
#shared_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Shared_data/"
#args$info_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Compute_variance_explained/variance_explained.many_inds.no_corr.tsv"
#args$info_p="/scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix/Analysis.N_TEST_10000.N_TRAIN_1000/Sort_phenos_by_var/phenos.txt"
#args$n_traing = 1000
#args$n_test = 1000
#args$seed=1
#args$id_x_name_p = paste0(shared_p,"phenotype_selection_for_GAM.txt")
#args$caucasians_p = paste0(shared_p,"UKB_caucasian.zk_ids.txt")
#args$gwas_sample_p = paste0(shared_p,"non_overlapping_caucasian_samples.txt")
#args$sex_p = paste0(shared_p,"UKB_sex.self_reported_and_genetic.txt")
#args$cov_p = paste0(shared_p, "/Covariates.txt.gz")

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

phenos = read.table(args$info_p, sep='\t')$V1
start=Sys.time()

# Import GWAS samples
gwas_sample_df = na.omit(fread(args$gwas_sample_p, select=c(1))) # samples used in GWAS
names(gwas_sample_df) = c("IID")

# Import caucasians
ukb_caucasian = read.table(args$caucasians_p)
names(ukb_caucasian ) = c("IID")

# Import sex (only gwas women)
sex_df = na.omit(read.table(args$sex_p, hea=T))
names(sex_df) = c("IID", "sex_reported", "sex_genetic")
sex_df = sex_df[sex_df$sex_reported == sex_df$sex_genetic, ]

# Import covariates
cov_df = fread(args$cov_p, select=c("IID", "age", "sex"))

# Import phenotypes and 
get_pheno = function(pheno){
	#PARAM="/data/FAC/FBM/DBC/zkutalik/default_sensitive/rhofmeis/data/UKBB/Phenotypes/data/phenotype_selection_for_GAM.txt"
	#param_df = read.table(PARAM, hea=F, sep='\t')
	#TYPE=param_df[param_df$V1 == pheno, ]$V2
	#PHF=paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/rhofmeis/data/UKBB/Phenotypes/file_per_phecode/",TYPE,"/", pheno,".txt.gz")

	pheno_folder = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Compute_variance_explained/Scaled_phenotypes/pheno_"
	PHF = paste0(pheno_folder, pheno, ".tsv.gz")
	pheno_df = na.omit(fread(PHF, hea=T, select=c(1,5)))
	names(pheno_df) = c("IID", paste0("PHENO_", pheno))

	# No need to add normalization, they should already have mean = 0, sd=1
	cat("Pheno", pheno, "imported with", nrow(pheno_df), "individuals with non-NA values.", "\n")
	#if(TYPE=="mod_bt") {cat("Categories for trait:", unique(pheno_df$PHENO))}
	return(pheno_df)
}

# Import phenotypes and 
get_pheno_idfx = function(pheno){
	PARAM="/data/FAC/FBM/DBC/zkutalik/default_sensitive/rhofmeis/data/UKBB/Phenotypes/data/phenotype_selection_for_GAM.txt"
	param_df = read.table(PARAM, hea=F, sep='\t')
	TYPE=param_df[param_df$V1 == pheno, ]$V2
	PHF=paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/rhofmeis/data/UKBB/Phenotypes/file_per_phecode/",TYPE,"/", pheno,".txt.gz")
	pheno_df = na.omit(fread(PHF, hea=T, select=c(2,3)))
	names(pheno_df) = c("IID", paste0("PHENO_", pheno))

	# No need to add normalization, they should already have mean = 0, sd=1
	cat("Pheno", pheno, "imported with", nrow(pheno_df), "individuals with non-NA values.", "\n")
	#if(TYPE=="mod_bt") {cat("Categories for trait:", unique(pheno_df$PHENO))}
	return(pheno_df)
}



get_pgs = function(pheno){
	pgs_p=paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Compute_polygenic_scores/LDpred2_150K/PGS_calc/pheno_",pheno,"/score/aggregated_scores.txt.gz")
	pgs_df = na.omit(fread(pgs_p, hea=T, select=c(2,5))) #, select=c("iid", "pgsavg"))
	names(pgs_df) = c("IID", paste0("PGS_", pheno))
	# Add normalization
	#pgs_df[, 2] = scale(pgs_df[[2]])
	cat("pgs ", pheno, "imported with", nrow(pgs_df), "individuals with non-na values.", "\n")
	return(pgs_df)
}

merged_pheno_df = NULL; merged_pgs_df = NULL
merged_pheno_df_idfx = NULL;
for(pheno in phenos){
	pheno_df = get_pheno(pheno)
	pheno_df_idfx = get_pheno_idfx(pheno)
	pgs_df = get_pgs(pheno)
	if(pheno == phenos[1]) {merged_pheno_df = pheno_df; merged_pheno_df_idfx = pheno_df_idfx; }
	else {merged_pheno_df = merge(merged_pheno_df, pheno_df, by="IID");
		merged_pheno_df_idfx = merge(merged_pheno_df_idfx, pheno_df_idfx, by="IID") }

	if(pheno == phenos[1]) {merged_pgs_df = pgs_df}
	else {merged_pgs_df = merge(merged_pgs_df, pgs_df, by="IID")}
}

# Filter non-caucasian individuals and find overlapping samples between datasets
matched_samples = intersect(merged_pheno_df_idfx$IID, intersect(merged_pgs_df$IID, merged_pheno_df$IID)) # overlap between df
cat("Keep overlaping samples:", length(matched_samples), "individuals left\n")
matched_samples = intersect(matched_samples, ukb_caucasian$IID) # only gwas caucasians
cat("Filter out non caucasians:", length(matched_samples), "individuals left\n")
matched_samples = setdiff(matched_samples, gwas_sample_df$IID) # remove gwas samples
cat("Filter out gwas samples:", length(matched_samples), "individuals left\n")

id_pgs = match(matched_samples, merged_pgs_df$IID)
id_pheno = match(matched_samples, merged_pheno_df$IID)
id_pheno_idfx = match(matched_samples, merged_pheno_df_idfx$IID)
merged_pgs_df = merged_pgs_df[id_pgs, ]
merged_pheno_df = merged_pheno_df[id_pheno, ]
merged_pheno_df_idfx = merged_pheno_df_idfx[id_pheno_idfx, ]
stopifnot(identical(merged_pheno_df$IID, merged_pgs_df$IID))
stopifnot(identical(merged_pheno_df_idfx$IID, merged_pgs_df$IID))

end=Sys.time()
cat(paste("PGS and PHENO imported in", round(end-start, 4)) , fill=TRUE)
cat("Number of individuals left:", nrow(merged_pheno_df), "\n")

#------------------------------------------------------------------------------#
# Downsample datasets
#------------------------------------------------------------------------------#
shuffled_rows = sample(c(1:nrow(merged_pgs_df)))
merged_pgs_df = merged_pgs_df[shuffled_rows,]
merged_pheno_df = merged_pheno_df[shuffled_rows,]
merged_pheno_df_idfx = merged_pheno_df_idfx[shuffled_rows,]

rows_10K = c(1:args$n_train); rows_train = c((args$n_train+1):(2*args$n_train)); rows_test = c((1+2*args$n_train):(2*args$n_train+args$n_test))

set_10K_pgs = merged_pgs_df[rows_10K, ]; set_10K_pheno = merged_pheno_df[rows_10K, ]
set_train_pgs = merged_pgs_df[rows_train, ]; set_train_pheno = merged_pheno_df[rows_train, ]
set_test_pgs = merged_pgs_df[rows_test, ]; set_test_pheno = merged_pheno_df[rows_test, ]
set_train_pgs_h0 = set_train_pgs[sample(1:nrow(set_train_pgs)), ]
set_test_pgs_h0 = set_test_pgs[sample(1:nrow(set_test_pgs)), ]
stopifnot(nrow(set_train_pgs_h0) == nrow(set_train_pgs))

#------------------------------------------------------------------------------#
# Write output datasest for our method
#------------------------------------------------------------------------------#

write_df = function(df, out){
	print(out)
	out_gz = gzfile(out, "w")
	write.table(df, file=out_gz, row.names=F, quote=F, sep="\t")
	close(out_gz)
}

write_df(set_10K_pheno, args$out_pheno_10K); write_df(set_10K_pgs, args$out_pgs_10K)
write_df(set_train_pheno, args$out_pheno_train); write_df(set_train_pgs, args$out_pgs_train)
write_df(set_test_pheno, args$out_pheno_test); write_df(set_test_pgs, args$out_pgs_test)
write_df(set_train_pgs_h0, args$out_pgs_train_h0)
write_df(set_test_pgs_h0, args$out_pgs_test_h0)

#------------------------------------------------------------------------------#
# Write output dataset for IDEFIX
#------------------------------------------------------------------------------#

get_pheno_idfx = function(phenos, cov_df, pheno_df) { # merge covariates with phenotype
	cov_df$str_sex = "Female"
	cov_df[cov_df$sex == 1,]$str_sex = "Male"
	cov_df$sex = cov_df$str_sex
	cov_df[, str_sex:= NULL]
	cov_x_pheno_df = merge(cov_df, pheno_df, by="IID")
	cov_x_pheno_df = cov_x_pheno_df[match( pheno_df$IID, cov_x_pheno_df$IID),]

	# create output phenotype df
	final_pheno_df = NULL
	for (pheno_id in c(1:length(phenos))){
		pheno_name=phenos[pheno_id]
		sub_df = cov_x_pheno_df[, c("IID", "age", "sex")]
		print(sub_df)
		names(sub_df) = c("ID", "AGE", "SEX")
		sub_df[, "TRAIT"] = pheno_name
		sub_df[, "VALUE"] = cov_x_pheno_df[[3+pheno_id]]
		if(pheno_id==1){ final_pheno_df = sub_df}
		else { final_pheno_df = rbind(final_pheno_df, sub_df)}
	}
	return(final_pheno_df)
}

get_pgs_idfx  = function(phenos, pgs_df){
	names(pgs_df) = c("IID", phenos)
	final_pgs_df = NULL
	for (pheno_id in c(1:length(phenos))){
		pheno_name = phenos[pheno_id]
		sub_df = pgs_df[, "IID"]
		sub_df[, "TRAIT"] = pheno_name
		sub_df[, "VALUE"] = pgs_df[[1+pheno_id]]
		if(pheno_id==1){ final_pgs_df = sub_df}
		else { final_pgs_df = rbind(final_pgs_df, sub_df)}
	}
	return(final_pgs_df)
}


set_idfx_pheno = get_pheno_idfx(phenos, cov_df, merged_pheno_df_idfx[c(rows_train, rows_test), ])
set_idfx_pgs = get_pgs_idfx(phenos, merged_pgs_df[c(rows_train, rows_test), ])

write_df(set_idfx_pheno, args$out_pheno_idfx)
write_df(set_idfx_pgs, args$out_pgs_idfx)

write_df(data.table(pheno_id=names(merged_pheno_df_idfx), type=as.vector(sapply(merged_pheno_df_idfx, class))),
	args$out_mapping)
