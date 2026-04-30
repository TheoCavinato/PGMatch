library(argparse)
library(data.table)
library(PRROC)
library(ggplot2)
library(ggpubr)
library(MetBrewer)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
parser$add_argument("--concat_data", required=T)

parser$add_argument("--out_pdf", required=T)
args <- parser$parse_args()

# debugging
args$concat_data = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Plots//concat_all_phenos.tsv"
args$out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Plots/test.pdf"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import data 
concat_dt = fread(args$concat_data)
names(concat_dt) = c("proba", "method", "group", "n_pheno", "itr")

# function that will resample the individuals n times depending on the numebr of match
precrec_subsset = function(df_h0, df_h1, method, n_pheno) {
	recall_grid <- seq(0, 1, length.out = 100)

	pr_matrix <- do.call(cbind, lapply(c(1:100), function(i) {
	  pr <- pr.curve(
	    scores.class1 = subset(df_h0, itr==i)$proba,
	    scores.class0 = subset(df_h1, itr==i)$proba,
	    curve = TRUE)
	  approx(pr$curve[,1], pr$curve[,2], xout = recall_grid)$y
	}))
	df_pr = data.table(Recall=recall_grid,
		Precision=rowMeans(pr_matrix),
		SE =apply(pr_matrix, 1, sd) / sqrt(ncol(pr_matrix)),
		MaxPrec = apply(pr_matrix, 1, max),
		MinPrec = apply(pr_matrix, 1, min)
		)
	df_pr$method = method
	df_pr$n_pheno = n_pheno

	return(df_pr)
}

# get precision recall for match
df_pr_match = NULL
df_pr_mismatch = NULL

for(nbr_pheno in c(10,20,c(21:29),30,c(31:39),40)){
	message("Using ", nbr_pheno, " phenotypes")
	for (cur_method in c("supervised", "unsupervised")){
	df_h0 = subset(concat_dt, n_pheno == nbr_pheno & group=="H0" & method == cur_method)
	df_h1 = subset(concat_dt, n_pheno == nbr_pheno & group=="H1" & method == cur_method)
	df_pr_match = rbind(df_pr_match, precrec_subsset(df_h0, df_h1, cur_method, nbr_pheno))

	df_h0$proba = 1 - df_h0$proba
	df_h1$proba = 1 - df_h1$proba
	df_pr_mismatch = rbind(df_pr_mismatch, precrec_subsset(df_h1, df_h0, cur_method, nbr_pheno))
	}
}

#------------------------------------------------------------------------------#
# Make plot
#------------------------------------------------------------------------------#

plot_function = function(plot_df, cur_title, legend_show){
palette = met.brewer("Hokusai3", length(unique(plot_df$n_pheno)))
p = ggplot(plot_df, aes(x = Recall, y = Precision, fill=as.factor(n_pheno) , color=as.factor(n_pheno))) +
  geom_line() +
  #geom_ribbon(aes(
  #  #ymin = Precision - 1.96 * SE,
  #  #ymax = Precision + 1.96 * SE
  #  ymin = MaxPrec,
  #  ymax = MinPrec
  #),alpha=0.2, color=NA) +
  theme_bw() +
  ylim(c(0.5,1)) +
  xlim(c(0,1)) +
  scale_colour_manual(values= palette) +
  scale_fill_manual(values= palette) +
  labs(color="Nbr. of traits", title=cur_title) +
  theme(legend.position = c(0.2,0.2),
  legend.background = element_rect(color = "black"),
    legend.title = element_text(margin = margin(r = 10)),
    plot.title = element_text(hjust=0.5))

  if(!legend_show) p = p + theme(legend.position = "none")
  return(p)
}

n_pheno_plot = c(10,20,30,40)
p_match_sup = plot_function(subset(df_pr_match, n_pheno %in% n_pheno_plot & method=="supervised"), "Supervised", T)
p_mismatch_sup = plot_function(subset(df_pr_mismatch, n_pheno %in% n_pheno_plot & method=="supervised"), "Supervised", F)
p_match_unsup = plot_function(subset(df_pr_match, n_pheno %in% n_pheno_plot & method=="unsupervised"), "Unsupervised", F)
p_mismatch_unsup = plot_function(subset(df_pr_mismatch, n_pheno %in% n_pheno_plot & method=="unsupervised"), "Unsupervised", F)

#p_final = ggarrange(p_match_sup, p_match_unsup, p_mismatch_sup, p_mismatch_unsup, ncol=2, nrow=2)
#ggsave(args$out_pdf, height=10, width=10)
p_final = ggarrange(p_match_sup, p_match_unsup, ncol=2, nrow=1, labels=c("C","D"))
title <- grid::textGrob("Identifying matches",
                        gp = grid::gpar(fontsize = 14, fontface = "bold"))

p_final_final = ggarrange(title,
	p_final,
          ncol = 1,
          heights = c(0.1, 1))

ggsave(args$out_pdf, height=5.5, width=10)

#------------------------------------------------------------------------------#
# Make subplot
#------------------------------------------------------------------------------#

n_pheno_plot = c(10,20,30,39)
p_match_sup = plot_function(subset(df_pr_match, n_pheno %in% n_pheno_plot & method=="supervised"), "Supervised", T)
p_mismatch_sup = plot_function(subset(df_pr_mismatch, n_pheno %in% n_pheno_plot & method=="supervised"), "Supervised", F)
p_match_unsup = plot_function(subset(df_pr_match, n_pheno %in% n_pheno_plot & method=="unsupervised"), "Unsupervised", F)
p_mismatch_unsup = plot_function(subset(df_pr_mismatch, n_pheno %in% n_pheno_plot & method=="unsupervised"), "Unsupervised", F)

#p_final = ggarrange(p_match_sup, p_match_unsup, p_mismatch_sup, p_mismatch_unsup, ncol=2, nrow=2)
#ggsave(args$out_pdf, height=10, width=10)
p_final = ggarrange(p_match_sup, p_match_unsup, ncol=2, nrow=1, labels=c("C","D"))
title <- grid::textGrob("Identifying matches",
                        gp = grid::gpar(fontsize = 14, fontface = "bold"))

p_final_final = ggarrange(title,
	p_final,
          ncol = 1,
          heights = c(0.1, 1))

ggsave(args$out_pdf, height=5.5, width=10)


