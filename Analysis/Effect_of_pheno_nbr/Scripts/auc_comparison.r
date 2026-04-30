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
parser$add_argument("--out_auc_table", required=T)
args <- parser$parse_args()

# debugging
#args$concat_data = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Plots//concat_all_phenos.tsv"
#args$out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Plots/test.pdf"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import data 
concat_dt = fread(args$concat_data)
names(concat_dt) = c("proba", "method", "group", "n_pheno", "itr")

# function that will resample the individuals n times depending on the numebr of match
auc_subset = function(df_h0, df_h1, method, n_pheno) {
	recall_grid <- seq(0, 1, length.out = 100)

	return(data.table(auc = unlist(lapply(c(1:100), function(i) {
	  pr.curve(
	    scores.class1 = subset(df_h0, itr==i)$proba,
	    scores.class0 = subset(df_h1, itr==i)$proba,
	    curve = TRUE)$auc.integral
	})),
	method = method,
	n_pheno = n_pheno))
}

# get precision recall for match
df_auc_match = NULL
df_auc_mismatch = NULL

for(nbr_pheno in c(10,20,30,40)){
	for (cur_method in c("supervised", "unsupervised")){
	df_h0 = subset(concat_dt, n_pheno == nbr_pheno & group=="H0" & method == cur_method)
	df_h1 = subset(concat_dt, n_pheno == nbr_pheno & group=="H1" & method == cur_method)
	df_auc_match = rbind(df_auc_match, auc_subset(df_h0, df_h1, cur_method, nbr_pheno))

	df_h0$proba = 1 - df_h0$proba
	df_h1$proba = 1 - df_h1$proba
	df_auc_mismatch = rbind(df_auc_mismatch, auc_subset(df_h1, df_h0, cur_method, nbr_pheno))
	}
}

auc_table_match = subset(df_auc_match, method=="supervised")[, .(mean_auc_match = round(mean(auc),4)), by = .(n_pheno, method)]
auc_table_match$mean_auc_unsupervised = subset(df_auc_match, method=="unsupervised")[, .(mean_auc = round(mean(auc),4)), by = .(n_pheno, method)]$mean_auc
auc_table_match$Inf_type = "match"
auc_table_mismatch = subset(df_auc_mismatch, method=="supervised")[, .(mean_auc_match = round(mean(auc),4)), by = .(n_pheno, method)]
auc_table_mismatch$mean_auc_unsupervised = subset(df_auc_mismatch, method=="unsupervised")[, .(mean_auc = round(mean(auc),4)), by = .(n_pheno, method)]$mean_auc
auc_table_mismatch$Inf_type = "mismatch"
auc_table = rbind(auc_table_match, auc_table_mismatch)
auc_table[, method := NULL]
setcolorder(auc_table, c("n_pheno","Inf_type","mean_auc_match","mean_auc_unsupervised"))
fwrite(auc_table, args$out_auc_table, sep="\t")
#auc_table$mean_auc_mismatch = df_auc_mismatch[, .(mean_auc = mean(auc)), by = .(method, n_pheno)]$mean_auc
#print(auc_table)
# get precision recall for mismatch

#------------------------------------------------------------------------------#
# Make plot
#------------------------------------------------------------------------------#

bind_match_mismatch = rbind( copy(df_auc_mismatch)[, group := "mismatch"],
	copy(df_auc_match)[, group := "match"])

plot_function = function(plot_df, cur_title, show_legend, min_y){
palette = met.brewer("Homer1", 2, direction=-1)
p = ggplot(plot_df, aes(x = as.factor(n_pheno), y = auc, colour=as.factor(group))) +
	geom_boxplot(position = position_dodge(width = 0.8))  +
	theme_bw() +
	theme(plot.title = element_text(hjust=0.5),
	legend.position = c(0.7,0.2),
	legend.background = element_rect(color="black"),
	legend.text = element_text( margin = margin(r = 5)),
	legend.title = element_blank())+
	stat_compare_means(method = "t.test", label = "p.signif", method.args = list(alternative = "greater"), show.legend=F) +
	labs(title=cur_title, y="AUPRC", x="Nbr. of traits") +
	scale_colour_manual(values = palette, name="") +
	ylim(min_y, 1)

	if(!show_legend) p = p + theme(legend.position = "none")

	return(p)
}

min_y = min(bind_match_mismatch$auc)
p_sup = plot_function(subset(bind_match_mismatch, method=="supervised"), "Supervised", T, min_y)
p_unsup = plot_function(subset(bind_match_mismatch, method=="unsupervised"), "Unsupervised", F, min_y)
p_final = ggarrange(p_sup, p_unsup, ncol=2, nrow=1)
#ggsave(args$out_pdf, width=10, height=5)

p_final = ggarrange(p_sup, p_unsup, ncol=2, nrow=1,labels=c("E","F"))
title <- grid::textGrob("Identifying Matches and Mimsatches",
                        gp = grid::gpar(fontsize = 14, fontface = "bold"))

p_final_final = ggarrange(title,
	p_final,
          ncol = 1,
          heights = c(0.1, 1))

ggsave(args$out_pdf, height=5.5, width=10)

