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
#args$concat_data = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_prior/Plots/concat.tsv"
#args$out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_prior//Plots/test.pdf"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import data 
concat_dt = fread(args$concat_data)
names(concat_dt) = c("itr", "method", "group", "proba")

# function that will resample the individuals n times depending on the numebr of match
precrec_subset = function(concat_dt, cur_method, n_match, n_mismatch) {
	recall_grid <- seq(0, 1, length.out = 100)

	df_h0 = subset(concat_dt, method==cur_method & group == "H0")
	df_h1 = subset(concat_dt, method==cur_method & group == "H1")
	stopifnot(nrow(df_h0)==1e4 * 100)
	stopifnot(nrow(df_h1)==1e4 * 100)

	pr_matrix <- do.call(cbind, lapply(c(1:100), function(i) {
	sub_df_h0 = subset(df_h0, itr==i)[sample(1:1e4, n_mismatch, replace=F)]
	sub_df_h1 = subset(df_h1, itr==i)[sample(1:1e4, n_match, replace=F)]
	stopifnot(nrow(sub_df_h0)==n_mismatch)
	stopifnot(nrow(sub_df_h1)==n_match)
	pr = pr.curve(
	    scores.class1 = sub_df_h0$proba,
	    scores.class0 = sub_df_h1$proba,
	    curve = TRUE)
	approx(pr$curve[,1], pr$curve[,2], xout = recall_grid)$y}))

        df_pr = data.table(Recall=recall_grid,
                Precision=rowMeans(pr_matrix))
	df_pr$Method = cur_method
	df_pr$ratio = paste0(n_match/100, ":", n_mismatch/100)

	return(df_pr)
}

# get precision recall for different values of match and mismatch across the 100 simulations
df_pr = NULL
for (cur_method in c("PGMatch", "IDEFIX")){
	message(cur_method)
	for(n_val in c(1e3,1e4)){
	message( n_val, " ",1e2)
	df_pr = rbind(df_pr, precrec_subset(concat_dt, cur_method, n_val, 1e2))
	message(  1e2, " ", n_val)
	df_pr = rbind(df_pr, precrec_subset(concat_dt, cur_method, 1e2, n_val))
	}
	message(  1e2, " ", 1e2)
	df_pr = rbind(df_pr, precrec_subset(concat_dt, cur_method, 1e2, 1e2))
}
#for (cur_method in c("PGMatch", "IDEFIX")){
#	message(cur_method)
#	for(n_val in c(1e2,1e3)){
#	message( n_val, " ",1e4)
#	df_pr = rbind(df_pr, precrec_subset(concat_dt, cur_method, n_val, 1e4))
#	message(  1e4, " ", n_val)
#	df_pr = rbind(df_pr, precrec_subset(concat_dt, cur_method, 1e4, n_val))
#	}
#	message(  1e4, " ", 1e4)
#	df_pr = rbind(df_pr, precrec_subset(concat_dt, cur_method, 1e4, 1e4))
#}

#------------------------------------------------------------------------------#
# Make plot
#------------------------------------------------------------------------------#

df_pr$ratio = factor(df_pr$ratio, levels = c("100:1", "10:1", "1:1", "1:10", "1:100"))
df_pr$Method = factor(df_pr$Method, levels = c("PGMatch", "IDEFIX"))
palette = met.brewer("Hokusai2", length(unique(df_pr$ratio)))
palette = met.brewer("Hiroshige", length(unique(df_pr$ratio)))
p = ggplot(df_pr, aes(x = Recall, y = Precision, color=ratio, linetype=Method)) +
  geom_line() +
  theme_bw() +
  ylim(c(0,1)) +
  xlim(c(0,1)) +
  scale_colour_manual(values= palette) +
    scale_linetype_manual(values = c("PGMatch" = "22", "IDEFIX" = "solid")) +
  labs(color="Ratio\nMatch:Mismatch") +
  theme(
  legend.background = element_rect(color = "black"),
    legend.title = element_text(margin = margin(r = 10)),
    plot.title = element_text(hjust=0.5))

ggsave(args$out_pdf, height=5, width=7)

