library(ggplot2)
library(data.table)
library(argparse)
library(ggpubr)

# Goal: plot distribution of LLRs

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--llr_test_h0_prefix", required = T)
parser$add_argument("--llr_test_h1_prefix", required = T)
parser$add_argument("--llr_train_h0_prefix", required = T)
parser$add_argument("--llr_train_h1_prefix", required = T)
parser$add_argument("--n_phenos", required=T)

parser$add_argument("--out_png", required = T)

# Parse the args
args <- parser$parse_args()
n_phenos <- as.numeric(strsplit(args$n_phenos, ",")[[1]])

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#
df_pr = NULL
plot_list = list()
itr=1
for (n_pheno in n_phenos){
	llr_test_h0_p = paste0(args$llr_test_h0_prefix, n_pheno, ".tsv.gz")
	llr_test_h1_p = paste0(args$llr_test_h1_prefix, n_pheno, ".tsv.gz")
	llr_train_h0_p = paste0(args$llr_train_h0_prefix, n_pheno, ".tsv.gz")
	llr_train_h1_p = paste0(args$llr_train_h1_prefix, n_pheno, ".tsv.gz")
	llr_test_dt = rbind(data.table(llr=fread(llr_test_h0_p)$llr, group="H0"),
		data.table(llr=fread(llr_test_h1_p)$llr, group="H1"))
	llr_train_dt = rbind(data.table(llr=fread(llr_train_h0_p)$llr, group="H0"),
		data.table(llr=fread(llr_train_h1_p)$llr, group="H1"))

	#------------------------------------------------------------------------------#
	# Make plot
	#------------------------------------------------------------------------------#

	palette = c("#dd5129", "#43b284")
	p = ggplot() +
	  geom_density(
	    data = llr_train_dt,
	    aes(x = llr, y = after_stat(density), color=group),
	    alpha = 0.5
	  ) +
	geom_density(
	    data = llr_test_dt,
	    aes(x = llr, y = -after_stat(density), color=group),
	    alpha = 0.5
	  ) +
	  scale_color_manual(values=palette) +
	  geom_hline(yintercept = 0) +
	  theme_bw() +
	  labs(x= "Log-likelihood ratio (LLR)", y="Density", color=NULL,linetype=NULL, title=paste(n_pheno, "phenotypes")) +
	  theme(legend.position =c(0.2,0.7),
		plot.title = element_text(hjust=0.5))

	plot_list[[itr]] = p
	itr=itr+1
}

print(length(n_phenos))
print(length(plot_list))
p_final = ggarrange(plotlist = plot_list, nrow=1)
ggsave(args$out_png, height=5, width = 30)
