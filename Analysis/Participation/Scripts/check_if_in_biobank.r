library(PearsonDS)
library(data.table)
library(ggplot2)
library(reshape2)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--pgs_p", required=T)
parser$add_argument("--prefix_proba", required=T)
parser$add_argument("--suffix", required=T)
parser$add_argument("--biobank_size", required=T, help="Will scale the size of the biobank accordingly when trying to predict the phenotype", type="integer")
# output
parser$add_argument("--out_tsv", required=T)
args <- parser$parse_args()

## debugging
#args$pgs_p = "/scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank//Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000.SEED_1//Datasets/pgs.test.tsv.gz"
#args$prefix_proba="/scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank//Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000.SEED_1//Probas/probas.unsupervised.h2.ldsc_cg.ldsc_cg.idx_"
#args$suffix= ".tsv.gz"
#args$biobank_size = 10

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import pgs (just to get the iids)
pgs_iids = fread(args$pgs_p, hea=T)$IID

#------------------------------------------------------------------------------#
# Compute weighted average
#------------------------------------------------------------------------------#

cat("IID","MEAN_W", "MEAN_WO", "MAX_W", "MAX_WO", fill=T, sep='\t', file=args$out_tsv)
for(idx in c(1:1000)){

	# import data
	proba_p = paste0(args$prefix_proba, idx, args$suffix)
	proba_df = fread(proba_p, hea=T)
	ori_iid = unique(proba_df$IID)
	proba_df$IID = pgs_iids

	# play with biobank size
	sub_iids = sample(pgs_iids[pgs_iids != ori_iid], (args$biobank_size-2))
	sub_iids_w = c(ori_iid,sub_iids[-1])
	sub_iids_wo = sub_iids

	sub_proba_df_w = proba_df[proba_df$IID %in% sub_iids_w, ]
	sub_proba_df_wo = proba_df[proba_df$IID %in% sub_iids_wo, ]

	# commpute mean of the probabilities
	mean_w = mean(sub_proba_df_w$Proba)
	mean_wo = mean(sub_proba_df_wo$Proba)

	# get maximum value in biobank
	max_w = max(sub_proba_df_w$Proba)
	max_wo = max(sub_proba_df_wo$Proba)

	cat(ori_iid, mean_w, mean_wo, max_w, max_wo, fill=T, sep='\t', append=T, file=args$out_tsv)
}

