library(data.table)
library(PRROC)
library(ggplot2)

get_data = function(p0, p1){
df_h0 = fread(p0)
df_h1 = fread(p1)

pr <- pr.curve(
scores.class1 = df_h0$Proba,
scores.class0 = df_h1$Proba,
curve = TRUE)

return (data.frame(pr$curve))
}


true_dt = get_data("/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/PGMatch_results/qnorm_true/proba.sup.test.H0.tsv.gz", "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/PGMatch_results/qnorm_true/proba.sup.test.H1.tsv.gz")
false_dt = get_data("/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/PGMatch_results/qnorm_false/proba.sup.test.H0.tsv.gz", "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/PGMatch_results/qnorm_false/proba.sup.test.H1.tsv.gz")

true_dt$group = "true"
false_dt$group = "false"
p = ggplot(rbind(true_dt, false_dt), aes(x=X1, y=X2, color=group)) +	
	geom_line()

ggsave("/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/PGMatch_results/test.png")
