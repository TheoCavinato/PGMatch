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

parser$add_argument("--out_png", required=T)
args <- parser$parse_args()

# debugging
llr_folder = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Nbr_pheno_PHENONBR/itr_1/PGMatch_results/"
args$out_png = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_pheno_nbr//Plots/llr_dist.png"

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
	curr_llr_folder = gsub("PHENONBR", nbr_pheno, llr_folder)
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
	plot_df = subset(df, n_pheno == nbr_pheno & method == met)
	p = ggplot() +
	  geom_density(
	    data = plot_df,
	    aes(x = llr, y = after_stat(density),  linetype=type, color=group),
	    alpha = 0.5
	  ) +
	  theme_bw() +
	  theme(plot.title = element_text(hjust=0.5),
	  legend.position = c(0.2,0.8)) +
	  labs(title=cur_title)

	  if(!show_legend) p = p + theme(legend.position = "none")

	  return(p)
}

plot_list = list()
itr=1
for(nbr_pheno in c(10,20,30,40)){
	plot_list[[itr]] = plot_function(df, nbr_pheno, "unsup", paste0("Unsupervised\n", nbr_pheno,  " phenotypes"), (itr == 1 && nbr_pheno==10))
	itr=itr+1
	plot_list[[itr]] = plot_function(df, nbr_pheno, "sup", paste0("Supervised\n", nbr_pheno,  " phenotypes"), F)
	itr=itr+1
}

p_final = ggarrange(plotlist= plot_list, ncol = 2, nrow=4)
ggsave(args$out_png, height=20, width=10)
