library(ggplot2)
library(ggpubr)
library(data.table)
library(argparse)

# Make a boxplot to compare the two distributions

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--participation_p", required=T)
parser$add_argument("--biobank_size", required=T)
# output
parser$add_argument("--pdf_out", required=T)
args <- parser$parse_args()

## debugging
#args$participation_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Case_scenario_1_biobank/Participation_checking/supervised.biobank_size_10.nbr_pheno_40.n_test_100000.n_train_1000.seed_1.tsv"
#args$out_p = "test.png"

#------------------------------------------------------------------------------#
# Boxplot of the sum of the probabilities depending on whether
#an individual was part/ or not of the biobank
#------------------------------------------------------------------------------#

participation_df = fread(args$participation_p)

plot_func = function(df, col_name_a, col_name_b, y_axis){

	plot_df = data.table(
		sum_probas = c(df[[col_name_a]], df[[col_name_b]]),
		group = c(rep("Target in Biobank", nrow(df)), rep("Target not in Biobank", nrow(df)))
	)

	p = ggplot(plot_df, aes(x=group, y=sum_probas)) +
		geom_violin(fill="grey") +
		geom_boxplot(outlier.shape=NA) +
		#geom_jitter(alpha=0.5) +
		theme_bw() +
		labs(y=y_axis, x="") +
		theme(plot.title = element_text(hjust=0.5, face="bold"))
	

	median_a = median(df[[col_name_a]])
	median_b = median(df[[col_name_b]])
	diff_median = median_a - median_b
	cat("Difference of the medians:", diff_median, fill=T)
	return(p)

}


p1 = plot_func(participation_df, "MEAN_W", "MEAN_WO",  "Mean of the matching probabilities")
p2 = plot_func(participation_df, "MAX_W", "MAX_WO",  "Maximum of the matching probabilities")
p = ggarrange(p1,p2,ncol=2,nrow=1, labels="AUTO")
ggsave(args$pdf_out, width=10, height=5)

