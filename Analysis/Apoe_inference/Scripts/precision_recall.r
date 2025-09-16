library(argparse)
library(data.table)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--inference_p", required=T)
# ouptut
parser$add_argument("--out_tsv", required=T)
args <- parser$parse_args()

##debugging
#args$inference_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Apoe_inference/Results/inference.nbr_pheno_40.n_test_100000.n_train_1000.seed_1.biobank_size_10.supervised.tsv"

#------------------------------------------------------------------------------#
# Import data and compute precision recall for each individual
#------------------------------------------------------------------------------#


compute_prec_rec = function(df, inf_type, thresholds) {

	prec_rec_df = NULL
	for(threshold in thresholds){
		carriers = df[df$e4_possession == 1, ]
		non_carriers = df[df$e4_possession == 0, ]
		TP = sum(carriers[[inf_type]] >= threshold)
		FP = sum(non_carriers[[inf_type]] >= threshold)
		FN = sum(carriers[[inf_type]] < threshold)
		TN = sum(non_carriers[[inf_type]] < threshold)
		stopifnot(TP + FP + FN + TN == nrow(df))

		precision = TP / (TP + FP)
		recall = TP / (TP + FN)
		prec_rec_df = rbind(prec_rec_df, data.table(threshold = threshold,
			precision = precision,
			recall = recall,
			TP = TP,
			FP=FP,
			FN=FN,
			TN,
			inf_type = inf_type))
		}
		
	return(prec_rec_df)
}

# import inference df
inf_df = fread(args$inference_p)

# define thresholds
thresholds = c(0:1000)/1000

# perform bootstraping
boots = c(1:100)
precision_mat = matrix(nrow=length(thresholds), ncol=length(boots))
recall_mat = matrix(nrow=length(thresholds), ncol=length(boots))
for(boot in boots){
	labels_0 = sample(which(inf_df$e4_possession == 0), replace=T)
	labels_1 = sample(which(inf_df$e4_possession == 1), replace=T)
	stopifnot(length(labels_0) + length(labels_1) == nrow(inf_df))
	df = inf_df[c(labels_0, labels_1),]
	prec_rec = compute_prec_rec(df , "inf_w", thresholds)
	precision_mat[,boot] = prec_rec$precision
	recall_mat[,boot] = prec_rec$recall
}

precision_lower <- apply(na.omit(precision_mat), 1, function(x) quantile(x, 0.025))
precision_upper <- apply(na.omit(precision_mat), 1, function(x) quantile(x, 0.975))
recall_lower <- apply(na.omit(recall_mat), 1, function(x) quantile(x, 0.025))
recall_upper <- apply(na.omit(recall_mat), 1, function(x) quantile(x, 0.975))

# filter thresholds that could not be used because of NA
precision_thresholds = thresholds[rowSums(is.na(precision_mat)) == 0]
recall_thresholds = thresholds[rowSums(is.na(recall_mat)) == 0]
ci_prec_df = data.table(threshold = precision_thresholds, 
	precision_ci_lower = precision_lower,
	precision_ci_upper = precision_upper)
ci_rec_df = data.table(threshold = recall_thresholds, 
	recall_ci_lower = recall_lower,
	recall_ci_upper = recall_upper)

ci_df = merge(ci_prec_df, ci_rec_df, by="threshold", all=T)

# write actual pec rec df
prec_rec_df = compute_prec_rec(inf_df, "inf_w", thresholds)
final_prec_rec_df = merge(prec_rec_df, ci_df)
final_prec_rec_df 

#------------------------------------------------------------------------------#
# Write the ouptut (precision and recall)
#------------------------------------------------------------------------------#

write.table(final_prec_rec_df, args$out_tsv, quote=F, sep="\t", row.names=F)
