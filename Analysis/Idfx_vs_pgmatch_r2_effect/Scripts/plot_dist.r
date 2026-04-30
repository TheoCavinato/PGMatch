library(data.table)
library(ggplot2)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#


#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#


train_llr_h1_sherlock = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect//My_method//llr.test.h1.r2_file_r2_file_rand_all.txt.tsv.gz.sherlock.tsv.gz"
train_llr_h0_sherlock = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect//My_method//llr.test.h0.r2_file_r2_file_rand_all.txt.tsv.gz.sherlock.tsv.gz"
train_llr_h1_const = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect//My_method//llr.test.h1.r2_file_r2_file_rand_all.txt.tsv.gz.const.tsv.gz"
train_llr_h0_const = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect//My_method//llr.test.h0.r2_file_r2_file_rand_all.txt.tsv.gz.const.tsv.gz"


plot_df = rbind(
data.table(llr=fread(train_llr_h1_sherlock)$llr, method="classic", group="H1"),
data.table(llr=fread(train_llr_h0_sherlock)$llr, method="classic", group="H0"),
data.table(llr=fread(train_llr_h1_const)$llr, method="const", group="H1"),
data.table(llr=fread(train_llr_h0_const)$llr, method="const", group="H0")
)

print(plot_df)

p = ggplot(plot_df, aes(color = group, linetype=method, x=llr))  +
	geom_density()

ggsave("/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect/test.png")

p = ggplot(subset(plot_df, method=="classic"), aes(color = group, x=llr))  +
	geom_density()
ggsave("/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect/test.classic.png")
p = ggplot(subset(plot_df, method=="const"), aes(color = group, x=llr))  +
	geom_density()
ggsave("/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect/test.const.png")

p = ggplot(subset(plot_df, method=="classic"), aes(color = group, x=llr))  +
	geom_density() +
	xlim(c(-400,100))
ggsave("/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect/test.zoom_classic.png")
#
#p = ggplot() +
#	geom_density(plot_df, aes(color = group, linetype=group)) +
#	geom_density()
#
#ggsave("/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_me_r2_effect/test.2.png")
