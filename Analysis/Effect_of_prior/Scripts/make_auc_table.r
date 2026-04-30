library(data.table)
library(ggpubr)
library(MetBrewer)

options(scipen = 999) # turns off scientific notation

args=commandArgs(trailingOnly=T)
out_tsv = args[1]

plot_df = NULL
ratio_levels  = c()

n_mismatch = 100
n_matchs = c(10000, 1000)
for(n_match in n_matchs){
	#tmp_df =  fread(paste0("/scratch/tcavinat/Phenotype_inference_attack/Effect_of_prior/Plots/precrec.",n_match,".",n_mismatch,".tsv"))
	tmp_df =  fread(paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Plot_data/Effect_of_prior/auc.",n_match,".",n_mismatch,".tsv"))
	
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
	tmp_df =  fread(paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Plot_data/Effect_of_prior/auc.",n_match,".",n_mismatch,".tsv"))
	ratio_name = paste0(format(n_match/100, big.mark = "'", scientific = FALSE),
	":",
	format(n_mismatch/100, big.mark = "'", scientific = FALSE))
	tmp_df$ratio = ratio_name
	plot_df = rbind(plot_df, tmp_df)
	ratio_levels = c(ratio_levels, ratio_name)
	
}

plot_df$ratio = factor(plot_df$ratio, levels = ratio_levels)

# Make table
auc_table_sup = subset(plot_df, method=="supervised")[, .(mean_auc= round(mean(auc),4),
	sd_auc = round(sd(auc),4)),
	, by = .(method, ratio)]
auc_table_unsup = subset(plot_df, method=="unsupervised")[, .(mean_auc= round(mean(auc),4),
	sd_auc = round(sd(auc),4)),
	, by = .(method, ratio)]

auc_table = rbind(auc_table_sup, auc_table_unsup)

print(auc_table)
fwrite(auc_table, out_tsv, sep="\t")


