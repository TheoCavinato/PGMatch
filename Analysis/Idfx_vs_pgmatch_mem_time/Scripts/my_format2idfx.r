library(data.table)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--pheno_test_p", required=T)
parser$add_argument("--pheno_train_p", required=T)
parser$add_argument("--pgs_test_p", required=T)
parser$add_argument("--pgs_train_p", required=T)

# output
parser$add_argument("--out_pheno_train_idfx_p", required=T)
parser$add_argument("--out_pgs_train_idfx_p", required=T)
parser$add_argument("--out_pheno_test_idfx_p", required=T)
parser$add_argument("--out_pgs_test_idfx_p", required=T)
parser$add_argument("--out_mapping", required=T)

args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import and modify data
#------------------------------------------------------------------------------#

# import training ids
ori_df = fread(args$pheno_train_p)
ori_ids = ori_df$IID

# Import data you generated with create_dataset.r
import_and_make_long = function(test_p, train_p){
	df = rbind(fread(test_p), fread(train_p))
	setnames(df, old = names(df)[-1], new = sub(".*_", "", names(df)[-1]))
	df_long = melt(
	df,
	id.vars = "IID",
	variable.name = "TRAIT",
	value.name = "VALUE")
	return(df_long)
}

pheno_df = import_and_make_long(args$pheno_test_p, args$pheno_train_p)
pgs_df = import_and_make_long(args$pgs_test_p, args$pgs_train_p)

# merge phenotype with covariates
all_iids = unique(pheno_df$IID)
cov_df = data.table(
	IID = all_iids,
	age = 20 + as.integer(rnorm(length(all_iids), mean=20, sd=1)),
	sex = as.integer(runif(length(all_iids)) > 0.5)
	)
cov_df[, sex := ifelse(sex== 1, "Male", "Female")]

pheno_w_cov_df = merge(pheno_df, cov_df, by="IID")
names(pheno_w_cov_df) = c("ID", "TRAIT", "VALUE", "AGE","SEX")
pheno_w_cov_df = pheno_w_cov_df[, c("ID", "AGE","SEX", "TRAIT", "VALUE")]
setorder(pheno_w_cov_df, ID)
setorder(pgs_df, IID)
stopifnot(pgs_df$IID == pheno_w_cov_df$ID)

#------------------------------------------------------------------------------#
# Export data
#------------------------------------------------------------------------------#

# output tables
fwrite(subset(pheno_w_cov_df, ID %in% ori_ids), args$out_pheno_train_idfx_p, sep="\t")
fwrite(subset(pgs_df, IID %in% ori_ids), args$out_pgs_train_idfx_p, sep="\t")
fwrite(subset(pheno_w_cov_df, !(ID %in% ori_ids)), args$out_pheno_test_idfx_p, sep="\t")
fwrite(subset(pgs_df, !(IID %in% ori_ids)), args$out_pgs_test_idfx_p, sep="\t")

# output data type
setnames(ori_df, old = names(ori_df)[-1], new = sub(".*_", "", names(ori_df)[-1]))
data_type_df = data.table(pheno_id=names(ori_df)[-1], type=as.vector(sapply(ori_df[, -1], class)))

fwrite(data_type_df, args$out_mapping, sep="\t")
