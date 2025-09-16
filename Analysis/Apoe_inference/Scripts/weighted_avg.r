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
parser$add_argument("--pheno_p", required=T)
parser$add_argument("--prefix_proba", required=T)
parser$add_argument("--suffix", required=T)
parser$add_argument("--biobank_size", required=T, help="Will scale the size of the biobank accordingly when trying to predict the phenotype", type="integer")
# output
parser$add_argument("--out_tsv", required=T)
args <- parser$parse_args()

#args$pgs_p = "/scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank//Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000.SEED_1//Datasets/pgs.test.tsv.gz"
#args$pheno_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Apoe_inference//APOE_status/apoe_status.per_ind.txt"
#args$prefix_proba="/scratch/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank//Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000.SEED_1//Probas/probas.unsupervised.h2.ldsc_cg.ldsc_cg.idx_"
#args$suffix= ".tsv.gz"
#args$biobank_size = 10

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import pgs (just to get the iids)
pgs_iids = fread(args$pgs_p, hea=T)$IID

# import apoe
pheno_df= na.omit(fread(args$pheno_p))
names(pheno_df) = c("IID", "PHENO")
cat("APOE imported with", nrow(pheno_df), "individuals with non-NA values.", "\n")

# assess that we have the iids of all the test sets
stopifnot(length(intersect(pgs_iids, pheno_df$IID)) == length(pgs_iids))

# modify phenotype (binary, either you have it or not)
pheno_df$e4_count = 0
pheno_df[grepl("e4", pheno_df$PHENO), ]$e4_count = 1
frequencies = as.vector(table(pheno_df$e4_count) / nrow(pheno_df)) 
cat("Have e4 haplotype: 0, 1\n")
cat("Frequencies:", frequencies, "\n")

# sort individuals
match_ids = match(pgs_iids, pheno_df$IID)
pheno_df = pheno_df[match_ids, ]


#------------------------------------------------------------------------------#
# Compute weighted average
#------------------------------------------------------------------------------#

compute_wavg = function(df){
	df$scaled_proba = df$Proba / sum(df$Proba)
	weighted_avg = sum(df$e4_count * df$scaled_proba)
	return(weighted_avg)
}

cat(c("IID", "proba_w_self", "e4_possession", "haplotypes", "inf_w", "inf_wo"), sep="\t", fill=T, file=args$out_tsv) 
for(idx in c(1:1000)){
	# import data
	proba_p = paste0(args$prefix_proba, idx, args$suffix)
	proba_df = fread(proba_p, hea=T)
	ori_iid = unique(proba_df$IID)
	proba_df$IID = pgs_iids

	proba_df$e4_count = pheno_df$e4_count
	proba_df$PHENO = pheno_df$PHENO
	line_info = as.vector(as.matrix(proba_df[proba_df$IID == ori_iid, ]))

	sub_iids = sample(pgs_iids[pgs_iids != ori_iid], (args$biobank_size-2))
	sub_iids_w = c(sub_iids[-1],ori_iid)
	sub_iids_wo = sub_iids

	sub_proba_df = proba_df[proba_df$IID %in% sub_iids_w, ]
	sub_proba_df_not_him = proba_df[proba_df$IID %in% sub_iids_wo, ]

	# commpute proba in both cases
	weighted_avg = compute_wavg(sub_proba_df)
	weighted_avg_not_him = compute_wavg(sub_proba_df_not_him)

	cat(line_info, weighted_avg, weighted_avg_not_him, sep="\t", fill=T, file=args$out_tsv, append=T) 
	#cat(line_info, weighted_avg, weighted_avg_not_him, sep="\t", fill=T, append=T) 
}

