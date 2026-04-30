library(ggplot2)
library(data.table)
library(ggpubr)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# input
phenos  = c("30100","50","1747","30840","30080","30050","30110","30610","30760","30130","30260","30830","1727","30270","23102","30070","30010","30730","30640","30720","30880","30750","30300","30150","30770","30870","30710","30120","30700","30000","21001","30280","30860","30650","3062","30680","30600","8451","30810","30620")
df = NULL
pgs_p=paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Compute_polygenic_scores/LDpred2_150K/PGS_calc/pheno_",pheno_id,"/score/aggregated_scores.txt.gz")
caucas_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Shared_data/UKB_caucasian.zk_ids.txt"
gwas_samples_p  = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Shared_data/non_overlapping_caucasian_samples.txt"

# outptu
out_png = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/Datasets/plot_test.png"

#------------------------------------------------------------------------------#
# Compute Mean and Variance in subset of the UKB stats
#------------------------------------------------------------------------------#
get_pgs = function(pheno){
	pgs_p=paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Compute_polygenic_scores/LDpred2_150K/PGS_calc/pheno_",pheno,"/score/aggregated_scores.txt.gz")
	pgs_df = na.omit(fread(pgs_p, hea=T, select=c(2,4))) #, select=c("iid", "pgsavg"))
	names(pgs_df) = c("IID", paste0("PGS_", pheno))
	# Add normalization
	#pgs_df[, 2] = scale(pgs_df[[2]])
	cat("pgs ", pheno, "imported with", nrow(pgs_df), "individuals with non-na values.", "\n")
	return(pgs_df)
}

ukb_caucasian = read.table(caucas_p)
gwas_sample_df = na.omit(fread(gwas_samples_p, select=c(1))) # samples used in GWAS

merged_pgs_df = NULL
for(pheno in phenos){

	pgs_df = get_pgs(pheno)

	if(pheno == phenos[1]) {merged_pgs_df = pgs_df}
	else {merged_pgs_df = merge(merged_pgs_df, pgs_df, by="IID")}
}

caucas_pgs_df = subset(merged_pgs_df, IID %in% ukb_caucasian$V1)
in_gwas_caucas_pgs_df = subset(caucas_pgs_df, IID %in% gwas_sample_df$V1)
out_gwas_caucas_pgs_df = subset(caucas_pgs_df, !(IID %in% gwas_sample_df$V1))


out_results = data.table(pheno = phenos,
	mean_out = apply(out_gwas_caucas_pgs_df[, -"IID"], 2, mean),
	var_out = apply(out_gwas_caucas_pgs_df[, -"IID"], 2, var))
in_results = data.table(pheno = phenos,
	mean_in = apply(in_gwas_caucas_pgs_df[, -"IID"], 2, mean),
	var_in = apply(in_gwas_caucas_pgs_df[, -"IID"], 2, var))

#------------------------------------------------------------------------------#
# Get mean and variance from the summary statistics
#------------------------------------------------------------------------------#

sumstat_df = NULL
for(file_p in paste0("/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/Datasets/estimated_mean_and_var.pheno_",phenos,".txt")){
	sumstat_df = rbind(sumstat_df, fread(file_p))
}
names(sumstat_df) = c("pheno", "est_mean" , "true_mean", "est_var", "true_var")
sumstat_df$pheno = as.character(sumstat_df$pheno)

#------------------------------------------------------------------------------#
# Merge
#------------------------------------------------------------------------------#

plot_df = merge(merge(out_results, in_results, by="pheno"), sumstat_df, by="pheno")

plot_func = function(x_axis, y_axis, curr_title, min_val, max_val) {
p = ggplot(plot_df, aes_string(x=x_axis, y=y_axis)) +
	geom_point() + theme_bw() + labs(title = curr_title, x="Compute on all individuals PGS", y="Computed from summary statistics") +
	ylim(min_val, max_val) +
	xlim(min_val, max_val) 

	return(p)
}

head(plot_df)
p_mean = plot_func("true_mean", "est_mean", "Mean", min(min(plot_df$true_mean), min(plot_df$est_mean)), max(max(plot_df$true_mean), max(plot_df$est_mean)))
p_var = plot_func("true_var", "est_var", "Variance", min(min(plot_df$true_var), min(plot_df$est_var)), max(max(plot_df$true_var), max(plot_df$est_var)))

p_mean_out = plot_func("true_mean", "mean_out", "Out GWAS - Mean", min(min(plot_df$true_mean), min(plot_df$mean_out)), max(max(plot_df$true_mean), max(plot_df$mean_out)))
p_var_out = plot_func("true_var", "var_out", "Out GWAS - Variance", min(min(plot_df$true_var), min(plot_df$var_out)), max(max(plot_df$true_var), max(plot_df$var_out)))

p_mean_in = plot_func("true_mean", "mean_in", "In GWAS - Mean", min(min(plot_df$true_mean), min(plot_df$mean_in)), max(max(plot_df$true_mean), max(plot_df$mean_in)))
p_var_in = plot_func("true_var", "var_in", "In GWAS - Variance", min(min(plot_df$true_var), min(plot_df$var_in)), max(max(plot_df$true_var), max(plot_df$var_in)))

p_final = ggarrange(p_mean, p_var ,p_mean_in,p_var_in, p_mean_out, p_var_out, ncol=2, nrow=3)
ggsave(out_png, width=10, height=15)
