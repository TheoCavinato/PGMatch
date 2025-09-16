library(data.table)
library(ggplot2)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--pgs_p", required=T)
parser$add_argument("--prefix_proba", required=T)
parser$add_argument("--prefix_llr", required=T)
parser$add_argument("--suffix", required=T)
# output
parser$add_argument("--out_tsv", required=T)
args <- parser$parse_args()

## test datadaset
#args$pgs_p = "/scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000.SEED_1/Datasets/pgs.test.tsv.gz"
#args$prefix_llr="/scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000.SEED_1/LLR_computed/llr.test.idx_"
#args$prefix_proba="/scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000.SEED_1/Probas/probas.supervised.idx_"
#args$suffix=".tsv.gz"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import pgs to have the ids of genoems
pgs_ids = fread(args$pgs_p, hea=T)$IID

#------------------------------------------------------------------------------#
# Extract important information i.e. number of individuals above and proba
#of when true match
#------------------------------------------------------------------------------#

cat("llr_w_self", "llr_w_rand", "p_w_self", "p_w_rand", "above_self", "above_099", "above_0999", sep="\t", fill=T, file=args$out_tsv)
idx=1
for (idx in c(1:1000)){

	# import probabilities and LLR
	probas_p=paste0(args$prefix_proba, idx, args$suffix)
	llr_p=paste0(args$prefix_llr, idx, args$suffix)
	probas_df = fread(probas_p)
	llr_df = fread(llr_p)

	# find where the matching individual is individual
	stopifnot(length(unique(probas_df$IID)) == 1)
	proba_IID = unique(probas_df$IID)
	llr_IID = unique(llr_df$IID)
	stopifnot(proba_IID==llr_IID)
	match_idx = which(pgs_ids == proba_IID)
	
	# get LLR value
	llr_value = llr_df$llr[match_idx]

	# get proba value of match
	proba_value = probas_df$Proba[match_idx]
	#cat(proba_value, "\n")

	# get sames values for mismatch
	mismatch_idx = sample(c(1:1000)[!(c(1:1000) %in% match_idx)], 1)
	llr_value_mismatch = llr_df$llr[mismatch_idx]
	proba_value_mismatch = probas_df$Proba[mismatch_idx]

	# check how many individuals were above the 0.99 and 0.999 thresholds when comparing
	inds_above_099 = sum(probas_df$Proba > 0.99)
	inds_above_0999 = sum(probas_df$Proba > 0.999)

	# count number of individuals above the value
	inds_above = sum(probas_df$Proba > proba_value)
	cat(llr_value, llr_value_mismatch, proba_value, proba_value_mismatch, inds_above, inds_above_099, inds_above_0999, sep="\t", fill=T, file=args$out_tsv, append=T)
}


##------------------------------------------------------------------------------#
## Plot llr distributions
##------------------------------------------------------------------------------#
#
#plot_df = NULL
#for (idx in c(1:1000)){
#	# import probabilities and LLR
#	probas_p=paste0(args$prefix_proba, idx, args$suffix)
#	llr_p=paste0(args$prefix_llr, idx, args$suffix)
#	probas_df = fread(probas_p)
#	llr_df = fread(llr_p)
#
#	# find where the matching individual is individual
#	stopifnot(length(unique(probas_df$IID)) == 1)
#	proba_IID = unique(probas_df$IID)
#	llr_IID = unique(llr_df$IID)
#	stopifnot(proba_IID==llr_IID)
#	match_idx = which(pgs_ids == proba_IID)
#	
#	# get LLR value
#	llr_value = llr_df$llr[match_idx]
#
#	# get proba value of match
#	proba_value = probas_df$Proba[match_idx]
#	#cat(proba_value, "\n")
#
#	# count number of individuals above the value
#	inds_above = sum(probas_df$Proba > proba_value)
#	#cat(llr_value, proba_value, inds_above, sep="\t", fill=T, file=args$out_tsv, append=T)
#	cat(llr_value, proba_value, inds_above, sep="\t", fill=T, append=T)
#
#
#	plot_df = rbind(plot_df, data.table(llr_mismatch=llr_value, llr_match=llr_value_mismatch))
#	cat(llr_value, llr_value_mismatch, "\n")
#}
#
## make dataframe plotable
#final_plot_df = data.table(
#	llr = c(plot_df$llr_mismatch, plot_df$llr_match),
#	group = c(rep("mismatch", 1000), rep("match", 1000)))
#
#p = ggplot(final_plot_df, aes(x=llr, fill=group)) +
#	geom_histogram(position="identity", alpha=0.5)
#
#ggsave("/scratch/tcavinat/tmp/dis.test.png")

