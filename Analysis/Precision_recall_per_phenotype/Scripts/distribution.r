library(data.table)
library(argparse)
library(ggpubr)
library(PearsonDS)
library(MetBrewer)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--llr_test", required=T)
parser$add_argument("--llr_test_h0", required=T)
parser$add_argument("--moments", required=T)
parser$add_argument("--title", required=T)
# output
parser$add_argument("--show_legend", type="logical", required=T)
parser$add_argument("--out_png", required=T)
args <- parser$parse_args()

# debugging
#args$llr_test = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_precision_recall/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/LLR_computed/llr.test.r2.ldsc_cg.tsv.gz"
#args$llr_test_h0 = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_precision_recall/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/LLR_computed/llr.test.r2.ldsc_cg.h0.tsv.gz"
#args$moments = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_precision_recall/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/Moments/moments.unsupervised.r2.ldsc_cg.ldsc_cg.tsv"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import llr
llr_test_h1 = fread(args$llr_test, hea=T)
llr_test_h0 = fread(args$llr_test_h0, hea=T)
stopifnot(nrow(llr_test_h1) == nrow(llr_test_h0))
llr_df = data.table(
	group = c(rep("H0", nrow(llr_test_h0)), rep("H1", nrow(llr_test_h1))),
	llr = c(llr_test_h0$llr, llr_test_h1$llr))
cat("LLR imported\n")

# import moments
moments_df = fread(args$moments)
llr1_moments = as.vector(unlist(moments_df[1,]))
llr0_moments = as.vector(unlist(moments_df[2,]))
sim_h0 = rpearson(nrow(llr_test_h0), moments=llr0_moments)
sim_h1 = rpearson(nrow(llr_test_h1), moments=llr1_moments)
sim_df = data.table(
	group = c(rep("H0", nrow(llr_test_h0)), rep("H1", nrow(llr_test_h1))),
	llr = c(sim_h0, sim_h1))
cat("Moments imported\n")

#------------------------------------------------------------------------------#
# Plot histogram
#------------------------------------------------------------------------------#

#min_x = min(c(min(llr_df$llr), min(sim_df$llr)))
#max_x = max(c(max(llr_df$llr), max(sim_df$llr)))
min_x = -50
max_x = 30
palette = met.brewer("Egypt", 2)
palette = c("#dd5129", "#43b284")
p_llr = ggplot(llr_df, aes(x = llr, fill=group)) +
	#geom_density(alpha=0.5) +
	geom_histogram(alpha=0.5, bins=100, position="identity") +
	theme_bw() +
	xlim(c(min_x, max_x)) +
	theme( axis.title.x = element_blank(),
	axis.text.x = element_blank(),
	axis.ticks.x = element_blank(),
	axis.line.x = element_blank(),
	legend.position="none",
	legend.background = element_rect(fill = "white", color = "black", size=0.25)) +
	scale_fill_manual(values=palette) +
	labs(y="Observed count", fill=NULL)

if(args$show_legend==T) {
	p_llr = p_llr+theme(legend.position="inside", legend.position.inside=c(0.13,0.87))
} 
	
p_sim = ggplot(sim_df, aes(x = llr, fill=group)) +
	#geom_density(alpha=0.5) +
	geom_histogram(alpha=0.5, bins=100, position="identity") +
	scale_y_reverse() +
	theme_bw() +
	xlim(c(min_x, max_x)) +
	theme( axis.title.x = element_blank(),
	axis.ticks.x = element_blank(),
	axis.line.x = element_blank(),
	legend.position="none") +
	scale_fill_manual(values=palette) +
	labs(y="Expected count")

the_title <- text_grob(args$title, face = "bold", size = 14)
the_axis <- text_grob("Log-likelihood ratio (LLR)", size = 12)
p_final = ggarrange(the_title, p_llr, p_sim, the_axis, ncol=1, nrow=4, heights=c(0.1,1,1,0.07)) + bgcolor("White") + border(color=NA)
ggsave(args$out_png, width=5,height=8.8)
