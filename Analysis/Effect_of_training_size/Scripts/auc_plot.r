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
parser$add_argument("--out_tsv", required=T)
args <- parser$parse_args()

# debugging
#args$concat_data = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_training_size//Plots//concat_all_phenos.tsv"
#args$out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Effect_of_training_size//Plots/test.pdf"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import data 
concat_dt = fread(args$concat_data)
names(concat_dt) = c("proba", "method", "group", "n_train", "n_pheno", "itr")

# function that will resample the individuals n times depending on the numebr of match
auc_subset = function(df_h0, df_h1, method, n_train, n_pheno) {
	recall_grid <- seq(0, 1, length.out = 100)

	return(data.table(auc = unlist(lapply(c(1:100), function(i) {
	  pr.curve(
	    scores.class1 = subset(df_h0, itr==i)$proba,
	    scores.class0 = subset(df_h1, itr==i)$proba,
	    curve = TRUE)$auc.integral
	})),
	method = method,
	n_train = n_train,
	n_pheno = n_pheno))
}

# get precision recall for match
df_auc_match = NULL
df_auc_mismatch = NULL

for (nbr_train in c(100,200,300,400,500,1000,5000)){
	message(nbr_train)
	for(nbr_pheno in c(10, 20, 30 ,40)) {
	cur_method = "supervised"
	df_h0 = subset(concat_dt, n_train == nbr_train & group=="H0" & method == cur_method & n_pheno == nbr_pheno)
	df_h1 = subset(concat_dt, n_train == nbr_train & group=="H1" & method == cur_method & n_pheno == nbr_pheno)
	df_auc_match = rbind(df_auc_match, auc_subset(df_h0, df_h1, cur_method, nbr_train, nbr_pheno))

	df_h0$proba = 1 - df_h0$proba
	df_h1$proba = 1 - df_h1$proba
	df_auc_mismatch = rbind(df_auc_mismatch, auc_subset(df_h1, df_h0, cur_method, nbr_train, nbr_pheno))
	}
}

# Make table
auc_table_match = subset(df_auc_match, method=="supervised")[, .(mean_auc_match = round(mean(auc),4),
	sd_auc_match = round(sd(auc),4)),
	, by = .(n_pheno, method,n_train)]
auc_table_mismatch = subset(df_auc_mismatch, method=="supervised")[, .(mean_auc_mismatch = round(mean(auc),4),
	sd_auc_mismatch = round(sd(auc),4)),
	, by = .(n_pheno, method, n_train)]
auc_table = merge(auc_table_match, auc_table_mismatch, by=c("n_pheno","method","n_train"))
auc_table[, method := NULL]
fwrite(auc_table, args$out_tsv, sep="\t")

#------------------------------------------------------------------------------#
# Make plot
#------------------------------------------------------------------------------#

plot_function = function(plot_df, cur_title, show_legend, min_y){
palette = met.brewer("Hokusai3", 4)
p = ggplot(plot_df, aes(x = as.factor(n_train), y = auc, colour=as.factor(n_pheno))) +
	geom_boxplot(position = position_dodge(width = 0.8))  +
	theme_bw() +
	theme(plot.title = element_text(hjust=0.5),
	legend.position = c(0.8,0.2),
	legend.background = element_rect(color="black"),
	legend.text = element_text( margin = margin(r = 5)),
	legend.title = element_text(margin = margin(r = 10))
	)+
	labs(title=cur_title, y="AUPRC", x="Number of samples in the training set") +
	scale_colour_manual(values = palette, name="Nbr. of traits") +
	ylim(min_y, 1)

	if(!show_legend) p = p + theme(legend.position = "none")

	return(p)
}


min_y = min(c(df_auc_match$auc , df_auc_mismatch$auc))
p_match = plot_function(df_auc_match, "Match", T, min_y)
p_mismatch = plot_function(df_auc_mismatch, "Mismatch", F, min_y)
p_final = ggarrange(p_match, p_mismatch, ncol=2, nrow=1)
ggsave(args$out_pdf, width=10, height=5)
