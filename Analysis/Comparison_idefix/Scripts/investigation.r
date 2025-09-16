library(ggplot3)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# input
llr_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Idefix/Idefix_step_1/train_model_out/aggregatedLogLikelihoodRatiosMatrix.rds"
sllr_p = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Idefix/Idefix_step_1/train_model_out/scaledLogLikelihoodRatiosMatrix.rds"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

llr = readRDS(llr_p)
llr <- t(apply(llr, 1, function(x) scale(x)))

h1 = diag(llr) # match

h0_pos = cbind(c(1:(nrow(llr) - 1), nrow(llr)), c(2:ncol(llr), 1)) # take line just on top of diagonal
h0 = llr[h0_pos] # mismatch

#------------------------------------------------------------------------------#
# Plot
#------------------------------------------------------------------------------#

plot_df = data.frame(value=c(h0, h1), group=c(rep("h0", nrow(llr)), rep("h1", nrow(llr))))
p = ggplot(plot_df, aes(x=value, fill=group)) +
	geom_histogram(position="identity", alpha=0.5)

ggsave("/scratch/tcavinat/QualitativeTraits_2024_10_07/Assurancetourix_vs_idefix/test.my.sllr.png")
