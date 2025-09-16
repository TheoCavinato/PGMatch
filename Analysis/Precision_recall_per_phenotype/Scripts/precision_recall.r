library(data.table)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--prob_h1_p", required=T)
parser$add_argument("--prob_h0_p", required=T)
# output
parser$add_argument("--out_tsv", required=T)
args <- parser$parse_args()

# debugging
#args$prob_h1_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_precision_recall/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/Probas/probas.unsupervised.r2.ldsc_cg.ldsc_cg.tsv"
#args$prob_h0_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_precision_recall/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/Probas/probas.unsupervised.r2.ldsc_cg.ldsc_cg.h0.tsv"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#
prob_h1_df = fread(args$prob_h1_p, hea=T)
prob_h0_df = fread(args$prob_h0_p, hea=T)

#------------------------------------------------------------------------------#
# Compute precision recall with multiple thresholds
#------------------------------------------------------------------------------#

stopifnot(nrow(prob_h1_df) == nrow(prob_h0_df))
total_ind = nrow(prob_h1_df)*2
thresholds_middle = c(1:(1e2-1))/1e2
thresholds_low = 1/rev(c(1e3, 1e4,1e5,1e6, 1e7, 1e8, 1e9, 1e10))
thresholds_high = 1-thresholds_low
thresholds = c(thresholds_low, thresholds_middle, thresholds_high)

precision_list_match = c(); precision_list_mismatch = c()
recall_list_match = c(); recall_list_mismatch = c()
tp_list = c(); fp_list = c()
tn_list = c(); fn_list = c()

for (t in thresholds) {
	TP = sum(prob_h1_df$Proba > t)
	FP = sum(prob_h0_df$Proba > t)
	TN = sum(prob_h0_df$Proba <= t)
	FN = sum(prob_h1_df$Proba <= t)

	stopifnot(TP + FP + TN + FN == total_ind)

	precision_mismatch = TN/(TN+FN)
	recall_mismatch = TN/(TN+FP)

	precision_match = TP/(TP+FP)
	recall_match = TP/(TP+FN)

	precision_list_match = c(precision_list_match, precision_match)
	precision_list_mismatch = c(precision_list_mismatch, precision_mismatch)
	recall_list_match = c(recall_list_match, recall_match)
	recall_list_mismatch = c(recall_list_mismatch, recall_mismatch)
	tp_list = c(tp_list, TP)
	fp_list = c(fp_list, FP)
	tn_list = c(tn_list, TN)
	fn_list = c(fn_list, FN)
}

#------------------------------------------------------------------------------#
# Output
#------------------------------------------------------------------------------#
out_df = data.table(
	tp = tp_list,
	tn = tn_list,
	fp = fp_list,
	fn = fn_list,
	precision_match = precision_list_match,
	recall_match = recall_list_match,
	precision_mismatch = precision_list_mismatch,
	recall_mismatch = recall_list_mismatch,
	threshold = thresholds
	)
write.table( out_df, args$out_tsv,row.names=F, quote=F, sep='\t')
