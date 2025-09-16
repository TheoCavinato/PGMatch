library(data.table)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--prob_h1_p", required=T)
parser$add_argument("--prob_h0_prefix", required=T)
parser$add_argument("--biobank_size", required=T, type="integer") 
# output
parser$add_argument("--out_tsv", required=T)
args <- parser$parse_args()

## debugging
args$prob_h1_p = "/scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/itr_1/Probas/probas.unsupervised.h2.ldsc_cg.ldsc_cg.tsv"
args$prob_h0_prefix = "/scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/itr_1/Probas/probas.unsupervised.h2.ldsc_cg.ldsc_cg.h0.wheeled_"
args$biobank_size = 100000000

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#
ori_prob_h1_df = fread(args$prob_h1_p, hea=T)
prob_h0_df = NULL
for(wheel in c(0:999)){
	if (wheel%%100==0) { cat("Wheel", wheel, "...", fill=T) }
	prob_h0_p = paste0(args$prob_h0_prefix, wheel,".tsv")
	prob_h0_df = rbind(prob_h0_df, fread(prob_h0_p,  hea=T))
}
prob_h0_df = prob_h0_df[sample(c(1:nrow(prob_h0_df)), args$biobank_size), ]

# downsample prob_h1_df so that we have the correct equivalent of people
prob_h1_df = ori_prob_h1_df[sample(c(1:nrow(ori_prob_h1_df)), 1000),]

#------------------------------------------------------------------------------#
# Compute precision recall with multiple thresholds
#------------------------------------------------------------------------------#

thresholds_middle = c(1:(1e2-1))/1e2
thresholds_low = 1/rev(c(1e3, 1e4,1e5,1e6, 1e7, 1e8, 1e9, 1e10))
thresholds_high = 1-thresholds_low
thresholds = c(thresholds_low, thresholds_middle, thresholds_high)

precision_list_match = c(); precision_list_mismatch = c()
recall_list_match = c(); recall_list_mismatch = c()
tp_list = c(); fp_list = c()
tn_list = c(); fn_list = c()

total_ind = nrow(prob_h1_df) + nrow(prob_h0_df)

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
