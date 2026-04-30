library(data.table)
library(ggplot2)
library(ggpubr)
library(MetBrewer)

options(scipen = 999) # turns off scientific notation

args=commandArgs(trailingOnly=T)
out_pdf = args[1]

plot_df = NULL
ratio_levels  = c()

n_mismatch = 100
n_matchs = c(10000, 1000)
for(n_match in n_matchs){
	#tmp_df =  fread(paste0("/scratch/tcavinat/Phenotype_inference_attack/Effect_of_prior/Plots/precrec.",n_match,".",n_mismatch,".tsv"))
	tmp_df =  fread(paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Plot_data/Effect_of_prior/precrec.",n_match,".",n_mismatch,".tsv"))
	
	ratio_name = paste0(format(n_match/100, big.mark = "'", scientific = FALSE),
	":",
	format(n_mismatch/100, big.mark = "'", scientific = FALSE))
	tmp_df$ratio = ratio_name
	plot_df = rbind(plot_df, tmp_df)
	ratio_levels = c(ratio_levels, ratio_name)
	
}

n_match =100
n_mismatchs = c(100,1000,10000,100000, 1000000, 10000000)
for(n_mismatch in n_mismatchs){
	#tmp_df =  fread(paste0("/scratch/tcavinat/Phenotype_inference_attack/Effect_of_prior/Plots/precrec.",n_match,".",n_mismatch,".tsv"))
	tmp_df =  fread(paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Plot_data/Effect_of_prior/precrec.",n_match,".",n_mismatch,".tsv"))
	ratio_name = paste0(format(n_match/100, big.mark = "'", scientific = FALSE),
	":",
	format(n_mismatch/100, big.mark = "'", scientific = FALSE))
	tmp_df$ratio = ratio_name
	plot_df = rbind(plot_df, tmp_df)
	ratio_levels = c(ratio_levels, ratio_name)
	
}

plot_df$ratio = factor(plot_df$ratio, levels = ratio_levels)

plot_func = function(curr_method, curr_title){
	p = ggplot(subset(plot_df, method==curr_method), aes(x=Recall, y=Precision, color=as.factor(ratio) )) +
	geom_line() +
	theme_bw() +
	theme(plot.title = element_text(hjust=0.5),
	legend.background = element_rect(color="black"),
	legend.title = element_text(margin = margin(r=10))) +
	labs(title= curr_title, color="Ratio\nMatch:Mismatch") +
	scale_colour_manual(values = met.brewer("Hiroshige", length(unique(plot_df$ratio))))

	return(p)
}

p_sup = plot_func("supervised", "Supervised")
p_unsup = plot_func("unsupervised", "Unsupervised")
legend = get_legend(p_sup)
p_final = ggarrange(p_sup + theme(legend.position = "none"),
	p_unsup + theme(legend.position = "none"),
	legend,
	ncol=3, 
	widths= c(2,2,1))

ggsave(out_pdf ,  width=12.5, height=5)

