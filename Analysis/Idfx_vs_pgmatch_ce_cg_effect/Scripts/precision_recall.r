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
#args$data_df = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_ce_cg_effect//Plots//plot_effect_data.tsv"
#args$out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_ce_cg_effect//Plots//test.pdf"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import imformation to import
data_df = fread(args$data_df)

# import important information

df_pr = NULL
recall_grid <- seq(0, 1, length.out = 100)
for(cur_ce_cg_file in unique(data_df$ce_cg_file)){
for(cur_method in unique(data_df$method)){
	message(cur_ce_cg_file, " ", cur_method)
	cur_proba_dt = subset(data_df, ce_cg_file == cur_ce_cg_file & method == cur_method) 
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
		ce_cg_file=cur_ce_cg_file))
}
}

df_pr$method = factor(df_pr$method, levels = c("PGMatch", "IDEFIX"))
#------------------------------------------------------------------------------#
# Make plot
#------------------------------------------------------------------------------#

plot_function = function(curr_ce, curr_title){
p = ggplot(subset(df_pr, ce_cg_file==curr_ce), aes(x = Recall, y = Precision, linetype=method)) +
  geom_line() +
  theme_bw() +
  ylim(c(0,1)) +
  xlim(c(0,1))  +
  theme_bw() +
  theme( legend.background = element_rect(color="black"), plot.title = element_text(hjust=0.5)) +
    scale_linetype_manual(values = c("PGMatch" = "22", "IDEFIX" = "solid")) +
  labs(linetype="Method", title=curr_title) 
 }

p_ce_0.0_cg_0.0 = plot_function("ce_0.0_cg_0.0", "Scenario 1")+ theme(legend.position="none")
p_ce_0.0_cg_0.5 = plot_function("ce_0.0_cg_0.5", "Scenario 2") + theme(legend.position="none")
p_ce_0.5_cg_0.0 = plot_function("ce_0.5_cg_0.0", "Scenario 3")+ theme(legend.position="none")
p_ce_0.5_cg_0.5 = plot_function("ce_0.5_cg_0.5", "Scenario 4")+ theme(legend.position="none")
half_ce_0.5_cg_0.5_else_0.0 = plot_function("half_ce_0.5_cg_0.5_else_0.0", "Scenario 5" )+ theme(legend.position="none")

#p_ce_0.0_cg_0.5 = plot_function("ce_0.0_cg_0.5", "Ce = 0.0, Cg = 0.5") + theme(legend.position="none")
#p_ce_0.5_cg_0.5 = plot_function("ce_0.5_cg_0.5", "Ce = 0.5, Cg = 0.5")+ theme(legend.position="none")
#p_ce_0.0_cg_0.0 = plot_function("ce_0.0_cg_0.0", "Ce = 0.0, Cg = 0.0")+ theme(legend.position="none")
#p_ce_0.5_cg_0.0 = plot_function("ce_0.5_cg_0.0", "Ce = 0.5, Cg = 0.0")+ theme(legend.position="none")
#half_ce_0.5_cg_0.5_else_0.0 = plot_function("half_ce_0.5_cg_0.5_else_0.0", "Half Ce and Cg = 0.5, Half Ce and Cg = 0.0" )+ theme(legend.position="none")
#
legend_plot = plot_function("ce_0.0_cg_0.0", "Ce = 0.0, Cg = 0.0")
legend <- get_legend(legend_plot) 
p_final = ggarrange(p_ce_0.0_cg_0.0, p_ce_0.0_cg_0.5, p_ce_0.5_cg_0.0, p_ce_0.5_cg_0.5, half_ce_0.5_cg_0.5_else_0.0, legend, ncol=2, nrow=3)


ggsave(args$out_pdf, height=15, width=10)
