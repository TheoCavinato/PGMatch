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
parser$add_argument("--data_df", required=T)

parser$add_argument("--out_pdf", required=T)
args <- parser$parse_args()

# debugging
#args$data_df = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_r2_effect//Plots//plot_effect_data.tsv"
#args$out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_r2_effect//Plots//test.pdf"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import imformation to import
data_df = fread(args$data_df)

# import important information

df_pr = NULL
recall_grid <- seq(0, 1, length.out = 100)
for(cur_r2_file in unique(data_df$r2_file)){
for(cur_method in unique(data_df$method)){
	message(cur_r2_file, " ", cur_method)
	cur_proba_dt = subset(data_df, r2_file == cur_r2_file & method == cur_method) 
	stopifnot(nrow(cur_proba_dt) == 1000*100*2)
	pr_matrix <- do.call(cbind, lapply(c(1:100), function(i) {
	pr <- pr.curve(
	  scores.class1 = subset(cur_proba_dt, group=="H0" & itr==i)$proba,
	  scores.class0 = subset(cur_proba_dt, group=="H1" & itr==i)$proba,
	  curve = TRUE)
	  approx(pr$curve[,1], pr$curve[,2], xout = recall_grid)$y}))

	df_pr = rbind(df_pr, data.table(Recall=recall_grid,
		Precision=rowMeans(pr_matrix),
		SE =apply(pr_matrix, 1, sd) / sqrt(ncol(pr_matrix)),
		MaxPrec = apply(pr_matrix, 1, max),
		MinPrec = apply(pr_matrix, 1, min),
		method=cur_method,
		r2_file=cur_r2_file))
}
}

#------------------------------------------------------------------------------#
# Make plot
#------------------------------------------------------------------------------#

df_pr$method = factor(df_pr$method, levels = c("PGMatch", "IDEFIX"))
df_pr$r2_file = factor(df_pr$r2_file , levels = c("r2_file_0.5_all" , "r2_file_0.05_all" , "r2_file_0.5_half_0.05_half" , "r2_file_only_one_0.5_else_0.05"))
palette = met.brewer("Kandinsky", 4)
p = ggplot(df_pr, aes(x = Recall, y = Precision, color=r2_file, linetype=method)) +
  geom_line() +
  theme_bw() +
  ylim(c(0,1)) +
  xlim(c(0,1))  +
  theme_bw() +
    scale_linetype_manual(values = c("PGMatch" = "22", "IDEFIX" = "solid")) +
  theme(legend.position = c(0.3,0.3),
  	legend.background = element_rect(color="black")) +
  #scale_colour_manual(values = palette, labels=c(
  #      "r2_file_0.5_all" = "all r2 = 0.5",
  #      "r2_file_0.05_all" = "all r2 = 0.05",
  #      "r2_file_0.5_half_0.005_half" = "half r2 = 0.5, half r2 = 0.05",
  #      "r2_file_only_one_0.5_else_0.05" = "one r2 = 0.5, rest r2 = 0.05"
  #)) +
  scale_colour_manual(values = palette, labels=c(
        "r2_file_0.5_all" = "Scenario 1",
        "r2_file_0.05_all" = "Scenario 2",
        "r2_file_0.5_half_0.05_half" = "Scenario 3",
        "r2_file_only_one_0.5_else_0.05" = "Scenario 4"
  )) +

  labs(color="Var. explained distribution", linetype="Method")

ggsave(args$out_pdf, height=5, width=5)

