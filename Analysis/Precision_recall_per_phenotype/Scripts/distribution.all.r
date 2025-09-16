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
parser$add_argument("--parameters", required=T)
# output
parser$add_argument("--out_pdf", required=T)
args <- parser$parse_args()

#args$parameters = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_precision_recall/Export/parameters.tsv"
#args$out_pdf = "/scratch/tcavinat/QualitativeTraits_2024_10_07/Unsupervised_precision_recall/Export/merge.pdf"

# debugging
plot_func = function(llr_h0_p, llr_h1_p, moments_p, title_name, show_legend){

	#------------------------------------------------------------------------------#
	# Import data
	#------------------------------------------------------------------------------#
	# import llr
	llr_test_h1 = fread(llr_h1_p, hea=T)
	llr_test_h0 = fread(llr_h0_p, hea=T)
	stopifnot(nrow(llr_test_h1) == nrow(llr_test_h0))
	llr_df = data.table(
		group = c(rep("H0", nrow(llr_test_h0)), rep("H1", nrow(llr_test_h1))),
		llr = c(llr_test_h0$llr, llr_test_h1$llr))
	cat("LLR imported\n")

	# import moments
	moments_df = fread(moments_p)
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
	min_x = -50
	max_x = 30
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
		legend.background = element_rect(fill = "white", color = "black", size=0.25),
		legend.position="none") +
		scale_fill_manual(values=palette) +
		labs(y="Observed count", fill=NULL)

	
	if(show_legend==T) {
		p_llr = p_llr+theme(legend.position="inside", legend.position.inside=c(0.1,0.8))
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

	the_title <- text_grob(title_name, face = "bold", size = 14)
	the_axis <- text_grob("Log-likelihood ratio (LLR)", size = 12)
	p_final = ggarrange(the_title, p_llr, p_sim, the_axis, ncol=1, nrow=4, heights=c(0.1,1,1,0.07)) + bgcolor("White") + border(color=NA)
	return(p_final)
}

param_df = fread(args$parameters)

plot_list = list()
itr = 1
for(itr in c(1:nrow(param_df))){
	h0_p = param_df[itr,]$test_llr_h0
	h1_p = param_df[itr,]$test_llr_h1
	moments_p = param_df[itr,]$moments_p
	nbr_pheno = param_df[itr,]$nbr_pheno
	title_name = paste(nbr_pheno, "phenotypes")

	show_legend = (itr == 1)
	plot_list[[itr]] = plot_func(h0_p, h1_p, moments_p, title_name, show_legend)
	itr=itr+1
}

p_all = ggarrange(plotlist=plot_list, ncol=5, nrow=1)
ggsave(args$out_pdf, width=25,height=5)
