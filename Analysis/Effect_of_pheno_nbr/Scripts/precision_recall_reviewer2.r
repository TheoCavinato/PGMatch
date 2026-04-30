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

parser$add_argument("--out_png", required=T)
args <- parser$parse_args()

# debugging
#args$concat_data = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Plots//concat_all_phenos.tsv"
#args$out_png = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Plots/test.png"

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

for(nbr_pheno in c(10,20,30,40)){
	message(nbr_pheno)
	for (cur_method in c("supervised", "unsupervised", "reviewer2_unsupervised")){
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
palette = c( "#7ba0b4","#c27668", "#44728c")
p = ggplot(plot_df, aes(x = Recall, y = Precision, color=as.factor(method))) +
  geom_line() +
  theme_bw() +
  ylim(c(0.5,1)) +
  xlim(c(0,1)) +
  labs(color="Method", title=cur_title) +
  theme(legend.position = c(0.3,0.2),
  legend.background = element_rect(color = "black"),
    legend.title = element_text(margin = margin(r = 10)),
    legend.text = element_text( margin = margin(r = 5)),
    plot.title = element_text(hjust=0.5)) +
    scale_colour_manual(values = palette,
    labels=c("supervised" = "Supervised",
    	"reviewer2_unsupervised" = "Unsupervised + CE",
    	"unsupervised"="Unsupervised"))

  if(!legend_show) p = p + theme(legend.position = "none")
  return(p)
}

df_pr_match$method = factor(df_pr_match$method, levels=c("supervised", "reviewer2_unsupervised", "unsupervised"))
p_match_10 = plot_function(subset(df_pr_match, n_pheno==10), "10 traits", T)
p_match_20 = plot_function(subset(df_pr_match, n_pheno==20), "20 traits", F)
p_match_30 = plot_function(subset(df_pr_match, n_pheno==30), "30 traits", F)
p_match_40 = plot_function(subset(df_pr_match, n_pheno==40), "40 traits", F)

p_final = ggarrange( p_match_10, p_match_20, p_match_30, p_match_40, ncol=2,nrow=2)

ggsave(args$out_png, width=10, height=10)
