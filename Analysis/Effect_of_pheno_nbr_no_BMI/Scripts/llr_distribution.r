library(argparse)
library(data.table)
library(ggplot2)
library(ggpubr)
library(MetBrewer)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
parser$add_argument("--llr_folder", required=T)

parser$add_argument("--out_all_pdf", required=T)
parser$add_argument("--out_40_pdf", required=T)
args <- parser$parse_args()

# debugging
#llr_folder = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Nbr_pheno_PHENONBR/itr_1/PGMatch_results/"
#args$out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Plots/llr_dist.pdf"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

import_data = function(f_path, method, group, type){
	return(data.table(
		llr = fread( paste0(f_path,"llr.",method,".",type,".",group,".tsv.gz"))$llr,
		group = group,
		method = method,
		type = type
		))
}

df = NULL
for(nbr_pheno in c(10,20,30,40)){
	curr_llr_folder = gsub("Nbr_pheno_", paste0("Nbr_pheno_",nbr_pheno), args$llr_folder)
	#curr_llr_folder = gsub("PHENONBR", nbr_pheno, args$llr_folder)
	tmp_df = rbind(import_data(curr_llr_folder, "sup", "H0", "train"),
	import_data(curr_llr_folder, "sup", "H1", "train"),
	import_data(curr_llr_folder, "unsup", "H0", "train"),
	import_data(curr_llr_folder, "unsup", "H1","train"),
	import_data(curr_llr_folder, "sup", "H0", "test"),
	import_data(curr_llr_folder, "sup", "H1", "test"),
	import_data(curr_llr_folder, "unsup", "H0", "test"),
	import_data(curr_llr_folder, "unsup", "H1","test"))
	tmp_df$n_pheno = nbr_pheno
	df = rbind(df, tmp_df)
}

#------------------------------------------------------------------------------#
# Make plots
#------------------------------------------------------------------------------#

plot_function = function(df, nbr_pheno, met, cur_title, show_legend){
	palette = c("#dd5129", "#43b284")
	plot_df = subset(df, n_pheno == nbr_pheno & method == met)
	p = ggplot() +
	  geom_density(
	    data = plot_df,
	    aes(x = llr, y = after_stat(density),  linetype=type, color=group),
	    alpha = 0.5
	  ) +
	  theme_bw() +
	  scale_color_manual(values=palette, name="") +
	  scale_linetype_manual(values= c("test" = "dashed", "train" = "solid"),
	  labels = c("test" = "Observed", "train" = "Expected"),
	  name="") +
	  theme(plot.title = element_text(hjust=0.5),
	  legend.position = c(0.2,0.7),
	legend.background = element_rect(color="black"),
	legend.text = element_text( margin = margin(r = 5)),
	legend.title = element_blank())+
	  labs(title=cur_title, x="Log−likelihood ratio (LLR)")

	  if(!show_legend) p = p + theme(legend.position = "none")

	  return(p)
}

# plot all
plot_list = list()
itr=1
#for(nbr_pheno in c(10,20,30,40)){
for(nbr_pheno in c(10,20,30)){
	plot_list[[itr]] = plot_function(df, nbr_pheno, "sup", paste0("Supervised\n", nbr_pheno,  " phenotypes"), (itr == 1 && nbr_pheno==10))
	itr=itr+1
	plot_list[[itr]] = plot_function(df, nbr_pheno, "unsup", paste0("Unsupervised\n", nbr_pheno,  " phenotypes"), F)
	itr=itr+1
}

p_final = ggarrange(plotlist= plot_list, ncol = 2, nrow=4)
ggsave(args$out_all_pdf, height=20, width=10)

# plot for 40 phenotypes
plot_list = list()
itr=1
for(nbr_pheno in c(40)){
	plot_list[[itr]] = plot_function(df, nbr_pheno, "sup", paste0("Supervised\n", nbr_pheno,  " phenotypes"), (itr == 1 && nbr_pheno==40))
	itr=itr+1
	plot_list[[itr]] = plot_function(df, nbr_pheno, "unsup", paste0("Unsupervised\n", nbr_pheno,  " phenotypes"), F)
	itr=itr+1
}

p_final = ggarrange(plotlist= plot_list, ncol = 2, nrow=1, labels="AUTO", widths=c(1,1))
#p_final = ggarrange(plotlist=plot_list,
#          ncol = 2,
#          nrow = 1,
#          heights = c(1, 1),
#	  labels = "AUTO",
#          top = grid::textGrob("LLR distributions",
#                               gp = grid::gpar(fontsize = 14, fontface = "bold")))
title <- grid::textGrob("LLR distributions",
                        gp = grid::gpar(fontsize = 14, fontface = "bold"))

p_final_final = ggarrange(title,
	p_final,
          ncol = 1,
          heights = c(0.1, 1))
ggsave(args$out_40_pdf, height=5.5, width=10)
