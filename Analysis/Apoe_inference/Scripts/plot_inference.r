library(ggplot2)
library(data.table)
library(argparse)
library(ggpubr)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--inference_sup", required=T)
parser$add_argument("--inference_unsup", required=T)
# output
parser$add_argument("--out_boxplot_with", required=T)
parser$add_argument("--out_boxplot_without", required=T)
args <- parser$parse_args()


# test parameters
args$inference_sup="/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Apoe_inference/Results/inference.nbr_pheno_40.n_test_100000.n_train_1000.seed_1.biobank_size_100000.supervised.tsv"
args$inference_unsup="/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Apoe_inference/Results/inference.nbr_pheno_40.n_test_100000.n_train_1000.seed_1.biobank_size_100000.unsupervised.tsv"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

inference_sup_df = fread(args$inference_sup)
inference_sup_df$e4_possession = as.factor(inference_sup_df$e4_possession)
inference_unsup_df = fread(args$inference_unsup)
inference_unsup_df$e4_possession = as.factor(inference_unsup_df$e4_possession)

# just check correlation of sup with usnup, out of curiosity
stopifnot(inference_sup_df$IID == inference_unsup_df$IID)
cor(inference_sup_df$proba_w_self, inference_unsup_df$proba_w_self)

# check the frequency of the haplotypes
table(inference_sup_df$e4_possession) / nrow(inference_sup_df)
cat("Variance sup e4 carriers", var(inference_sup_df[inference_sup_df$e4_possession == 1, ]$inf_w), fill=T)
cat("Variance sup e4 non-carriers", var(inference_sup_df[inference_sup_df$e4_possession == 0, ]$inf_w), fill=T)
cat("Number of e4 sup carriers", nrow(inference_sup_df[inference_sup_df$e4_possession==1,]), fill=T)
cat("Number of e4 sup non-carriers", nrow(inference_sup_df[inference_sup_df$e4_possession==0,]), fill=T)
t_test_sup = t.test(inference_sup_df[inference_sup_df$e4_possession==0,]$inf_w)
cat("T test p value sup", t_test_sup$p.value, fill=T)

cat("Variance unsup e4 carriers", var(inference_unsup_df[inference_unsup_df$e4_possession == 1, ]$inf_w), fill=T)
cat("Variance unsup e4 non-carriers", var(inference_unsup_df[inference_unsup_df$e4_possession == 0, ]$inf_w), fill=T)
cat("Number of e4 unsup carriers", nrow(inference_unsup_df[inference_unsup_df$e4_possession==1,]), fill=T)
cat("Number of e4 unsup non-carriers", nrow(inference_unsup_df[inference_unsup_df$e4_possession==0,]), fill=T)
t_test_unsup = t.test(inference_unsup_df[inference_unsup_df$e4_possession==0,]$inf_w)
cat("T test p value unsup", t_test_unsup$p.value, fill=T)



#------------------------------------------------------------------------------#
# Make plots
#------------------------------------------------------------------------------#

# boxplot 
plot_func = function(df, y_axis, title){
	p = ggplot(df, aes_string(x="e4_possession", y=y_axis)) +
		geom_violin(fill="grey") +
		geom_boxplot(outlier.shape=NA) +
		theme_bw() +
		#labs(x="e4 haplotype", y="e4 Score", title=title) +
		labs(x="", y= expression(paste("Pr(APOE-", epsilon, "4)")), title=title) +
		theme(plot.title=element_text(face="bold", hjust=0.5)) +
		scale_x_discrete(labels=c(expression(paste(epsilon, "4 carriers")), expression(paste(epsilon, "4 non-carriers"))))

	return(p)
}

p_sup = plot_func(inference_sup_df, "inf_w", "Supervised")
p_unsup = plot_func(inference_unsup_df, "inf_w", "Unsupervised")
final_plot = ggarrange(p_sup, p_unsup, nrow=1, ncol=2, labels=c("A","B"))
ggsave(args$out_boxplot_with, width=10, height=5)

p_sup = plot_func(inference_sup_df, "inf_wo", "Supervised")
p_unsup = plot_func(inference_unsup_df, "inf_wo", "Unsupervised")
final_plot = ggarrange(p_sup, p_unsup, nrow=1, ncol=2, labels=c("A","B"))
ggsave(args$out_boxplot_without, width=10, height=5)
