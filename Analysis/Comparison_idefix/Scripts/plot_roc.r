library(pROC)
library(data.table)
library(ggplot2)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

args=commandArgs(trailingOnly=T)

# input
#idfx_train_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Assess_train_100_test_100/Training/train_model_out_2_phenos.n_100/aggregatedLogLikelihoodRatiosMatrix.rds"
#idfx_test_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Assess_train_100_test_100/Testing/test_model_out_2_phenos.n_100/idefixPredictions.txt"
idfx_train_p = args[1]
idfx_test_p = args[2]

# my results
#me_train_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Assess_train_100_test_100/LLR_me/llr_train.2.n_100.tsv.gz"
#me_train_h0_p= "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Assess_train_100_test_100/LLR_me/llr_train.2.h0.n_100.tsv.gz"
#me_test_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Assess_train_100_test_100/LLR_me/llr_test.2.n_100.tsv.gz"
#me_test_h0_p= "/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/Assess_train_100_test_100/LLR_me/llr_test.2.h0.n_100.tsv.gz"
me_train_p = args[3]
me_train_h0_p= args[4]
me_test_p = args[5]
me_test_h0_p= args[6]


# ouptut
out_me = args[7]
out_idfx = args[8]

#------------------------------------------------------------------------------#
# Roc curves
#------------------------------------------------------------------------------#
# import idfx results
idfx_train_df = readRDS(idfx_train_p)
idfx_train_h1= as.vector(diag(idfx_train_df))
h0_pos = cbind(c(1:(nrow(idfx_train_df) - 1), nrow(idfx_train_df)), c(2:ncol(idfx_train_df), 1)) # take line just on top of diagonal
idfx_train_h0= idfx_train_df[h0_pos] # mismatch
idfx_train_h1_df = data.table( group=rep("H1", length(idfx_train_h1)), "llr"=c(idfx_train_h1))
idfx_train_h0_df = data.table( group=rep("H0", length(idfx_train_h0)), "llr"=c(idfx_train_h0))

# import idfx test results (careful, here we use the values predicted)
idfx_test_df= fread(idfx_test_p, hea=T)
idfx_test_df$llr = idfx_test_df$logLikelihoodRatios
idfx_test_h1_df= idfx_test_df[idfx_test_df$Var1 == idfx_test_df$Var2, ]
idfx_test_h0_df= idfx_test_df[idfx_test_df$Var1 != idfx_test_df$Var2, ]

# import my results
me_train_h1_df = fread(me_train_p, hea=T)
me_train_h0_df = fread(me_train_h0_p, hea=T)
me_test_h1_df = fread(me_test_p, hea=T)
me_test_h0_df = fread(me_test_h0_p, hea=T)
# be fair and use the same number in my test set than in idfx test set
me_test_h0_df = me_test_h0_df[sample(nrow(me_test_h0_df)/2),]
me_test_h1_df = me_test_h1_df[sample(nrow(me_test_h1_df)/2),]
stopifnot(nrow(me_test_h0_df) == nrow(idfx_test_h0_df))

#------------------------------------------------------------------------------#
# Validation histograms
#------------------------------------------------------------------------------#
hist_df = rbind(idfx_train_h1_df, idfx_train_h0_df)
p = ggplot(hist_df, aes(llr, fill=group)) +
	geom_histogram(position="identity", alpha=0.5)
ggsave(paste0(out_idfx, "hist.png"))
#------------------------------------------------------------------------------#
# Compute roc curve
#------------------------------------------------------------------------------#

# compute my roc curve
get_roc = function(df_h1, df_h0) {
	#roc_obj <- roc( c(rep(1, nrow(df_h1)), rep(0, nrow(df_h0))),
	#	c(df_h1$llr, df_h0$llr))
	llr_ts =  seq(min(c(df_h1$llr, df_h0$llr)) , max(c(df_h1$llr, df_h0$llr)), length.out=1e3)
	TP_list = c()
	FP_list = c()
	TN_list = c()
	FN_list = c()
	for(t in llr_ts) {
		TP_list = c(TP_list, sum(df_h1$llr > t))
		FP_list = c(FP_list, sum(df_h0$llr > t))
		TN_list = c(TN_list, sum(df_h0$llr <= t))
		FN_list = c(FN_list, sum(df_h1$llr <= t))
	}	
	plot_df= data.frame(
		TP = TP_list,
		FP = FP_list,
		FN = FN_list,
		TN = TN_list,
		thresholds = llr_ts
	)
	return(plot_df)

}
roc_me_train = get_roc(me_train_h1_df, me_train_h0_df)
roc_me_test = get_roc(me_test_h1_df, me_test_h0_df)
roc_idfx_train = get_roc(idfx_train_h1_df, idfx_train_h0_df)
roc_idfx_test = get_roc(idfx_test_h1_df, idfx_test_h0_df)

#------------------------------------------------------------------------------#
# Plot them
#------------------------------------------------------------------------------#

roc_me_train$group = "TRAIN"
roc_me_test$group = "TEST"
plot_me = rbind(roc_me_train, roc_me_test)
write.table(plot_me, out_me, row.names=F, quote=F, sep='\t')

roc_idfx_train$group = "TRAIN"
roc_idfx_test$group = "TEST"
plot_idfx = rbind(roc_idfx_train, roc_idfx_test)
write.table(plot_idfx, out_idfx, row.names=F, quote=F, sep='\t')
