library(data.table)
library(moments)
library(PearsonDS)
library(reshape2)
library(ggplot2)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# input 
data_p="/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/itr_1/Datasets/"
#data_p="/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_30.N_TEST_100000.N_TRAIN_1000/itr_1/Datasets/"
sex_p="/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Shared_data/UKB_sex.self_reported_and_genetic.txt"

llr_train_h1_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/itr_1/LLR_computed/llr.train.tsv.gz"
llr_train_h0_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/itr_1/LLR_computed/llr.train.h0.tsv.gz"

llr_test_h1_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/itr_1/LLR_computed/llr.test.tsv.gz"
llr_test_h0_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_40.N_TEST_100000.N_TRAIN_1000/itr_1/LLR_computed/llr.test.h0.tsv.gz"

llr_train_h1_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_34.N_TEST_20000.N_TRAIN_20000/itr_1/LLR_computed/llr.train.tsv.gz"
llr_train_h0_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_34.N_TEST_20000.N_TRAIN_20000/itr_1/LLR_computed/llr.train.h0.tsv.gz"
llr_test_h1_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_34.N_TEST_20000.N_TRAIN_20000/itr_1/LLR_computed/llr.test.tsv.gz"
llr_test_h0_p = "/scratch/tcavinat/Phenotype_inference_attack/Precision_recall_per_phenotype/Analysis.NBR_PHENO_34.N_TEST_20000.N_TRAIN_20000/itr_1/LLR_computed/llr.test.h0.tsv.gz"



# ouptut 
pheno_png = "/scratch/tcavinat/tmp/pheno_cor.png"
pgs_png = "/scratch/tcavinat/tmp/pgs_cor.png"

llr_test_png = "/scratch/tcavinat/tmp/llr_test.png"
llr_train_png = "/scratch/tcavinat/tmp/llr_train.png"

lymphocyte_png = "/scratch/tcavinat/tmp/lymphocyte.png"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import pheno and pgs
pheno_test_df = fread(paste0(data_p, "pheno.test.tsv.gz"))
pgs_test_df = fread(paste0(data_p, "pgs.test.tsv.gz"))
pheno_train_df = fread(paste0(data_p, "pheno.train.tsv.gz"))
pgs_train_df = fread(paste0(data_p, "pgs.train.tsv.gz"))

# import sex
sex_df = fread(sex_p)

# import llr


#------------------------------------------------------------------------------#
# Plot lymphocyte count vs lymphocyte percentage
#------------------------------------------------------------------------------#

lymphocyte_df = data.table(count = pheno_test_df$PHENO_30120, percentage= pheno_test_df$PHENO_30180)
lymphocyte_df = data.table(count = pheno_train_df$PHENO_30120, percentage= pheno_train_df$PHENO_30180)
nrow(lymphocyte_df)
p = ggplot(lymphocyte_df, aes(x=count, y=percentage)) +
	geom_point()
ggsave(lymphocyte_png)

#------------------------------------------------------------------------------#
# Look at the 
#------------------------------------------------------------------------------#

llr0_training= read.table(llr_train_h0_p, hea=T)$llr
llr1_training= read.table(llr_train_h1_p, hea=T)$llr
stopifnot(nrow(llr0_training)==nrow(llr1_training))
cat("LLR imported\n")

llr0_testing= read.table(llr_test_h0_p, hea=T)$llr
llr1_testing= read.table(llr_test_h1_p, hea=T)$llr
stopifnot(nrow(llr0_testing)==nrow(llr1_testing))
cat("LLR imported\n")

plot_llr = function(vec1, vec2, out_p){
	plot_df = data.table(llr = c(vec1, vec2),
		group=c(rep("H0",length(vec1)), rep("H1",length(vec2))))
	p = ggplot(plot_df, aes(x=llr, fill=group)) +
		geom_histogram(bins=100, position="identity", alpha=0.5) +
		xlim(-100,50)

	ggsave(out_p)
}
plot_llr(llr0_training, llr1_training, llr_train_png)
plot_llr(llr0_testing, llr1_testing, llr_test_png)

llr0_moments_train = c(mean(llr0_training), var(llr0_training), skewness(llr0_training), kurtosis(llr0_training))
llr1_moments_train = c(mean(llr1_training), var(llr1_training), skewness(llr1_training), kurtosis(llr1_training))
llr0_moments_test = c(mean(llr0_testing), var(llr0_testing), skewness(llr0_testing), kurtosis(llr0_testing))
llr1_moments_test = c(mean(llr1_testing), var(llr1_testing), skewness(llr1_testing), kurtosis(llr1_testing))
cat("Moments computed\n")
llr0_moments_train 
llr1_moments_train 
llr0_moments_test 
llr1_moments_test 

#------------------------------------------------------------------------------#
# Compute correlations
#------------------------------------------------------------------------------#

get_max_cor = function(df){
	cor_df = cor(df)
	diag(cor_df) = 0
	max_cor_df = max(cor_df)
	print(max_cor_df)
	return(max_cor_df)
}

cat("Correlation witht both males and females:\n")
max_pheno_test = get_max_cor(pheno_test_df)
max_pgs_test = get_max_cor(pgs_test_df)
max_pheno_train = get_max_cor(pheno_train_df)
max_pgs_train = get_max_cor(pgs_train_df)

#------------------------------------------------------------------------------#
# Same but stratistfy by sex
#------------------------------------------------------------------------------#

female_iids = sex_df[sex_df$sex_genetic==0,]$ID
male_iids = sex_df[sex_df$sex_genetic==1,]$ID

cor_per_sex = function(df, sex_ids){
	sub_df = df[df$IID %in% sex_ids,]
	max_cor = get_max_cor(sub_df)
	return(max_cor)
}

itr=0
for (sex_ids in list(female_iids, male_iids)){
	cat("Correlation for sex",itr," :\n")
	max_pheno_test_sex = cor_per_sex(pheno_test_df, sex_ids)
	max_pgs_test_sex = cor_per_sex(pgs_test_df, sex_ids)
	max_pheno_train_sex = cor_per_sex(pheno_train_df, sex_ids)
	max_pgs_train_sex = cor_per_sex(pgs_train_df, sex_ids)
	itr=itr+1
}

#------------------------------------------------------------------------------#
# Make plot of correlations 
#------------------------------------------------------------------------------#

corr_df = as.matrix(cor(pheno_test_df))

plot_df = melt(corr_df)

ggplot(plot_df, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "blue") +
  theme( legend.position="top", 
    axis.text.x = element_text(angle = 45, hjust = 1)) +
	labs(x="", y="", fill="correlation")

ggsave(pheno_png, width=12, height=12)
