library(ggplot2)
library(ggpubr)
library(data.table)
library(argparse)
library(PRROC)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
parser$add_argument("--n_pheno", required=T)
parser$add_argument("--idfx_prefix", required=T)
parser$add_argument("--me_prefix", required=T)
parser$add_argument("--me_scaled_prefix", required=T)

parser$add_argument("--out_png", required=T)
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

import_func = function(prefix, n_pheno){

	suffixes = c(
		".cor_min_cg_0.0.cor_max_cg_0.0.cor_min_ce_0.0.cor_max_ce_0.0.nbr_pheno_",
		".cor_min_cg_0.0.cor_max_cg_0.0.cor_min_ce_0.8.cor_max_ce_0.8.nbr_pheno_",
		".cor_min_cg_0.8.cor_max_cg_0.8.cor_min_ce_0.0.cor_max_ce_0.0.nbr_pheno_",
		".cor_min_cg_0.8.cor_max_cg_0.8.cor_min_ce_0.8.cor_max_ce_0.8.nbr_pheno_"
	)

	ptit_noms = c(
		"cg=ce=0.0",
		"cg=0.0,ce=0.8",
		"cg=0.8,ce=0.0",
		"cg=ce=0.8"
	)


	df_pr = NULL
	for (itr in c(1:length(suffixes))){
		suffix = suffixes[[itr]]
		ptit_nom = ptit_noms[[itr]]
		proba_p = paste0(prefix, suffix, n_pheno, ".tsv.gz")
		print(proba_p)
		proba_dt = fread(proba_p)
		# convert to precrec plot
		pr <- pr.curve(
		  scores.class0 = subset(proba_dt, truth=="H1")$proba,
		  scores.class1 = subset(proba_dt, truth=="H0")$proba,
		  curve = TRUE)

		tmp_df_pr <- as.data.frame(pr$curve)
		colnames(tmp_df_pr) <- c("Recall", "Precision", "Threshold")
		tmp_df_pr$group = ptit_noms[[itr]]
		df_pr = rbind(df_pr, tmp_df_pr)
	}
	return(df_pr)
}

dt_pr_idfx = import_func(args$idfx_prefix, args$n_pheno)
dt_pr_me = import_func(args$me_prefix, args$n_pheno)
dt_pr_me_scaled = import_func(args$me_scaled_prefix, args$n_pheno)

#------------------------------------------------------------------------------#
# Make plot
#------------------------------------------------------------------------------#
plot_func = function(df_pr, title){
	p = ggplot(df_pr, aes(x = Recall, y = Precision, color=group)) +
	  geom_line() +
	  labs(title = title) +
	  theme_bw() +
	  ylim(c(0,1)) +
	  xlim(c(0,1)) 

	return(p)
}

p_idfx = plot_func(dt_pr_idfx, "idfx")
p_me = plot_func(dt_pr_me, "me")
p_me_scaled = plot_func(dt_pr_me_scaled, "me scaled")

p_final = ggarrange(p_me, p_me_scaled , p_idfx,ncol=3, nrow=1)
ggsave(args$out_png, width=15, height=5)
