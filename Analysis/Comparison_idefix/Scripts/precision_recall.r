library(data.table)
library(ggplot2)
library(PearsonDS)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#
#args = commandArgs(trailingOnly=T)
#
## input
##me_h1_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/LLR_me/llr_train.2.tsv.gz"
##me_h0_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/LLR_me/llr_train.2.h0.tsv.gz"
##idfx_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Training/train_model_out_2_phenos/aggregatedLogLikelihoodRatiosMatrix.rds"
##mom_me_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Moments/2_cols.moments.tsv"
##mom_idfx_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Moments/2_cols.moments.idfx.tsv"
#argparse(me,us
#me_h1_p = args[1]
#me_h0_p = args[2]
#idfx_p = args[3]
#mom_me_p = args[4]
#mom_idfx_p  = args[5]
#
## output
##me_png = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Plots_me/me.hist.10.png"
##idfx_png = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Plots_idfx/idfx.hist.10.png"
##me_tsv = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/TSV_precision_recall/me.10.tsv"
##idfx_tsv = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/TSV_precision_recall/idfx.10.tsv"
#me_png = args[6]
#idfx_png = args[7]
#n_pheno = args[8]
#me_tsv = args[9] # will hold the TP, FP etc for different thresholds so that I can compute a precision recall locally
#idfx_tsv = args[10]
#me_pearson_png = args[11]
#idfx_pearson_png = args[12]

parser <- ArgumentParser()
# input
parser$add_argument("--me_h1_p", required=T)
parser$add_argument("--me_h0_p", required=T)
parser$add_argument("--idfx_p", required=T)
parser$add_argument("--mom_me_p", required=T)
parser$add_argument("--mom_idfx_p", required=T)

# output
parser$add_argument("--me_tsv", required=T)
parser$add_argument("--idfx_tsv", required=T)
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import me LLRs
me_h1_df = fread(args$me_h1_p, hea=T)
me_h0_df = fread(args$me_h0_p, hea=T)
stopifnot(nrow(me_h1_df) == nrow(me_h0_df))

me_df = data.table(llr= c(me_h1_df$llr, me_h0_df$llr),
	group = c(rep("h1", nrow(me_h1_df)), rep("h0", nrow(me_h0_df))))

# import the idfx
idfx_llr = readRDS(args$idfx_p)
idfx_h1 = diag(idfx_llr) # match
idfx_h0_pos = cbind(c(1:(nrow(idfx_llr) - 1), nrow(idfx_llr)), c(2:ncol(idfx_llr), 1)) # take line just on top of diagonal
idfx_h0 = idfx_llr[idfx_h0_pos] # mismatch

idfx_df = data.table(llr = c(idfx_h0, idfx_h1), group = c(rep("h0", nrow(idfx_llr)), rep("h1", nrow(idfx_llr))))

#------------------------------------------------------------------------------#
# Simualte pearson distributions
#------------------------------------------------------------------------------#
#me_moments_df = fread(args$mom_me_p)
#me_llr1_moments = as.vector(unlist(me_moments_df[1,]))
#me_llr0_moments = as.vector(unlist(me_moments_df[2,]))
#
#idfx_moments_df = fread(args$mom_idfx_p)
#idfx_llr1_moments = as.vector(unlist(idfx_moments_df[1,]))
#idfx_llr0_moments = as.vector(unlist(idfx_moments_df[2,]))
#
#n_sim = 1e4
#me_p1 = rpearson(n_sim, moments=me_llr1_moments)
#me_p0 = rpearson(n_sim, moments=me_llr0_moments)
#me_pearson_df = data.table(values = c(me_p1, me_p0), 
#	group=c(rep("H1", length(me_p1)), rep("H0", length(me_p0))))
#idfx_p1 = rpearson(n_sim, moments=idfx_llr1_moments)
#idfx_p0 = rpearson(n_sim, moments=idfx_llr0_moments)
#idfx_pearson_df = data.table(values = c(idfx_p1, idfx_p0), 
#	group=c(rep("H1", length(idfx_p1)), rep("H0", length(idfx_p0))))
#
#------------------------------------------------------------------------------#
# Plot pearson distributions
#------------------------------------------------------------------------------#
#p = ggplot(me_pearson_df, aes(x=values,fill=group) ) +
#	geom_histogram(position="identity", alpha=0.5, bins=100) +
#	theme_classic() +
#	theme(legend.position = "none", plot.title=element_text(hjust=0.5)) +
#	labs(title= paste0("Assurancetourix\n", n_pheno, " Phenotypes"), x="LLR", y="Count") 
#print(me_pearson_png)
#ggsave(me_pearson_png, width=4, height=4)
#p = ggplot(idfx_pearson_df, aes(x=values,fill=group) ) +
#	geom_histogram(position="identity", alpha=0.5, bins=100) +
#	theme_classic() +
#	theme(legend.position = "none", plot.title=element_text(hjust=0.5)) +
#	labs(title= paste0("Assurancetourix\n", n_pheno, " Phenotypes"), x="LLR", y="Count") 
#print(idfx_pearson_png)
#ggsave(idfx_pearson_png, width=4, height=4)
#

#------------------------------------------------------------------------------#
# Compute precision recall
#------------------------------------------------------------------------------#

thresholds = seq(-50, 50, 0.1)
cat("t","H1_SUP","H0_SUP","H1_BEL","H0_BEL","\n", file=args$me_tsv)
cat("t","H1_SUP","H0_SUP","H1_BEL","H0_BEL","\n", file=args$idfx_tsv)
for (t in thresholds) {
	me_H1_SUP=nrow(me_df[me_df$group=="h1" & me_df$llr > t,])
	me_H0_SUP=nrow(me_df[me_df$group=="h0" & me_df$llr > t,])
	me_H1_BEL=nrow(me_df[me_df$group=="h1" & me_df$llr <= t,])
	me_H0_BEL=nrow(me_df[me_df$group=="h0" & me_df$llr <= t,])
	cat(t,me_H1_SUP,me_H0_SUP,me_H1_BEL,me_H0_BEL,"\n", append=TRUE, file=args$me_tsv)

	idfx_H1_SUP=nrow(idfx_df[idfx_df$group=="h1" & idfx_df$llr > t,])
	idfx_H0_SUP=nrow(idfx_df[idfx_df$group=="h0" & idfx_df$llr > t,])
	idfx_H1_BEL=nrow(idfx_df[idfx_df$group=="h1" & idfx_df$llr <= t,])
	idfx_H0_BEL=nrow(idfx_df[idfx_df$group=="h0" & idfx_df$llr <= t,])
	cat(t,idfx_H1_SUP,idfx_H0_SUP,idfx_H1_BEL,idfx_H0_BEL,"\n", append=TRUE, file=args$idfx_tsv)
	#cat(t,idfx_H1_SUP,idfx_H0_SUP,idfx_H1_BEL,idfx_H0_BEL,"\n")

	stopifnot(me_H1_SUP+me_H0_SUP+me_H1_BEL+me_H0_BEL == nrow(idfx_df))
	stopifnot(idfx_H1_SUP+idfx_H0_SUP+idfx_H1_BEL+idfx_H0_BEL == nrow(idfx_df))
}

#------------------------------------------------------------------------------#
# Make plots
#------------------------------------------------------------------------------#

#p = ggplot(me_df, aes(x=llr,fill=group) ) +
#	geom_histogram(position="identity", alpha=0.5, bins=100) +
#	theme_classic() +
#	theme(legend.position = "none", plot.title=element_text(hjust=0.5)) +
#	labs(title= paste0("Assurancetourix\n", n_pheno, " Phenotypes"), x="LLR", y="Count") 
#ggsave(me_png, width=4, height=4)
#p = ggplot(idfx_df, aes(x=llr,fill=group) ) +
#	geom_histogram(position="identity", alpha=0.5, bins=100) + 
#	theme_classic() +
#	theme(legend.position = "none", plot.title=element_text(hjust=0.5)) +
#	labs(title= paste0("Idefix\n", n_pheno, " Phenotypes"), x="LLR", y="Count") 
#ggsave(idfx_png, width=4, height=4)
#print(idfx_png)

