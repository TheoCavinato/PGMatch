library(ggplot2)
library(data.table)
library(mvtnorm)

# Using a constant r2 instead of the actual r2 seem to work better
# but why?
# Here I try to address the problme directly thorugh simulations

n = 1e3
cat("Simulating data:\n")
r2 = c(0.924046, 0.593909, 0.306394, 0.578941, 0.740133, 0.786926, 0.43637, 0.332195, 0.77888, 0.100887)
#r2 = c(0.3529248, 0.3279128, 0.2788137, 0.2584552, 0.2166321, 0.2160767, 0.2069917, 0.1899249, 0.1854733, 0.1600537)

r=sqrt(r2)
n_pheno = length(r2)

G = matrix(rnorm(n * n_pheno, mean = 0, sd = 1), nrow = n, ncol = n_pheno)
E = matrix(rnorm(n * n_pheno, mean = 0, sd = 1), nrow = n, ncol = n_pheno)
PRS =G %*% diag(r)

X = PRS + E %*% diag(sqrt(1-r2))
apply(E %*% diag(sqrt(1-r2)), 2, var) + r2 # should be close to one everywhere
apply(X, 2, var)  # should be close to 1

cat("Computing LLR:\n")
compute_llr = function(X, PRS, r2, corr_mat_env) {
	scaled_PRS = scale(PRS)
	diff_mat = X - scaled_PRS %*% diag(sqrt(r2))
	corr_mat_env = cor(E %*% diag(sqrt(1-r2))) 

	p0 = dmvnorm(X,mean=rep(0,n_pheno),sigma=corr_mat_env,log = TRUE)
	p1_h1 = dmvnorm(diff_mat ,mean=rep(0,n_pheno),sigma= diag(sqrt(1-r2)) %*% corr_mat_env %*% diag(sqrt(1-r2)),log = TRUE)
	return(p1_h1 - p0)
}

quantile_norm = function(x){
    norm_dist = rnorm(length(x), mean=0, sd=1)
    ori_order = order(x)
    sorted_dist = x[ori_order]
    sorted_new_dist = sort(norm_dist)
    new_dist = sorted_new_dist[order(ori_order)]
    return(new_dist)
}

llr_h1 = compute_llr(X, PRS, r2)
llr_h0 = compute_llr(X, PRS[c(2:nrow(PRS), 1),], r2)

wrong_r2 = rep(0.5, n_pheno)
wrong_llr_h1 = compute_llr(X, PRS, wrong_r2)
wrong_llr_h0 = compute_llr(X, PRS[c(2:nrow(PRS), 1),], wrong_r2)

quant_norm_X = apply(X, 2, quantile_norm)
quant_norm_PRS = apply(PRS, 2, quantile_norm)
quant_norm_llr_h1 = compute_llr(quant_norm_X, quant_norm_PRS, r2)
quant_norm_llr_h0 = compute_llr(quant_norm_X, quant_norm_PRS, r2)

#cat("Try the quantile norm:\n")
#merged_pgs_df_scaled = apply(merged_pgs_df[,-c('IID')], 2, quantile_norm)
#merged_pheno_df_scaled = apply(merged_pheno_df[,-c('IID')], 2, quantile_norm)

cat("Plot result:\n")
plot_df = rbind(
	data.frame(llr=llr_h1, group="H1", method="classic"),
	data.frame(llr=llr_h0, group="H0", method="classic"),
	data.frame(llr=wrong_llr_h1, group="H1", method="const"),
	data.frame(llr=wrong_llr_h0, group="H0", method="const"),
	data.frame(llr=quant_norm_llr_h1, group="H1", method="quant_norm"),
	data.frame(llr=quant_norm_llr_h0, group="H0", method="quant_norm"))
p = ggplot(plot_df, aes(x=llr, color=group, linetype=method)) +
	geom_density()

ggsave("test.png")

cat("Use simulated data from the cluster:\n")
compute_llr_on_urblauna_data = function(pheno_p, pgs_p, ce_p, r2_p){ 
	merged_pheno_df = fread(pheno_p, hea=T)
	merged_pgs_df = fread(pgs_p, hea=T)
	r2 = read.table(r2_p, hea=T)$r2
	#corr_mat_env = as.matrix(fread(ce_p))
	corr_mat_env = cor(merged_pheno_df[, -c('IID')])
	corr_mat_env = diag()
	n_pheno = length(r2)
	#corr_mat_env = cor(E %*% diag(sqrt(1-r2))) 
	stopifnot(nrow(merged_pgs_df$IID)== nrow(merged_pheno_df$IID))
	stopifnot(length(r2) == (ncol(merged_pgs_df) - 1))

	merged_pgs_df_scaled = apply(merged_pgs_df[,-c('IID')], 2, quantile_norm)
	merged_pheno_df_scaled = apply(merged_pheno_df[,-c('IID')], 2, quantile_norm)

	diff_mat = merged_pheno_df_scaled - as.matrix(merged_pgs_df_scaled)%*%diag(sqrt(r2))

	p0_H1 = dmvnorm(merged_pheno_df_scaled,mean=rep(0,n_pheno),sigma=corr_mat_env,log = TRUE)
	p1_H1 = dmvnorm(diff_mat,mean=rep(0,n_pheno),sigma=diag(sqrt(1-r2))%*%corr_mat_env%*%diag(sqrt(1-r2)),log = TRUE)
	llr = p1_H1 - p0_H1
	return(llr)
}
urblauna_llr_h1 = compute_llr_on_urblauna_data("pheno.train.r2_file_r2_file_rand_all.txt.tsv.gz",
	"pgs.train.h1.r2_file_r2_file_rand_all.txt.tsv.gz",
	"ce.r2_file_r2_file_rand_all.txt.tsv.gz",
	"r2.r2_file_r2_file_rand_all.txt.tsv.gz"
)
urblauna_llr_h0 = compute_llr_on_urblauna_data("pheno.train.r2_file_r2_file_rand_all.txt.tsv.gz",
	"pgs.train.h0.r2_file_r2_file_rand_all.txt.tsv.gz",
	"ce.r2_file_r2_file_rand_all.txt.tsv.gz",
	"r2.r2_file_r2_file_rand_all.txt.tsv.gz"
)

# Under H1
cat("llr computed\n")

plot_df = rbind(
	data.frame(llr=llr_h1, group="H1", method="classic"),
	data.frame(llr=llr_h0, group="H0", method="classic"),
	data.frame(llr=wrong_llr_h1, group="H1", method="const"),
	data.frame(llr=wrong_llr_h0, group="H0", method="const"),
	#data.frame(llr=quant_norm_llr_h1, group="H1", method="quant_norm"),
	#data.frame(llr=quant_norm_llr_h0, group="H0", method="quant_norm"),
	data.frame(llr=urblauna_llr_h1, group="H1", method="urlaubna_method"),
	data.frame(llr=urblauna_llr_h0, group="H0", method="urlaubna_method"))

p = ggplot(plot_df, aes(x=llr, color=group, linetype=method)) +
	geom_density() +
	xlim(c(-200, 100))

ggsave("test.png")


## analysis of the ce computation
#corr_mat_env = cov2cor(cov(X) - cov(as.matrix(scale(PRS))%*%diag(sqrt(r2)))) # get Ce
#corr_mat_env = cov2cor(cov(X) - cov(as.matrix(scale(PRS))%*%diag(sqrt(r2)))) # get Ce
#
#cor(E) - corr_mat_env
#cov(X) - cov(PRS)
#
#Sigma_X   <- cov(X)
#Sigma_PRS <- cov(PRS)
#
#D_inv <- diag(1 / sqrt(1 - r2))
#
#Sigma_E <- D_inv %*% (Sigma_X - Sigma_PRS) %*% D_inv
#
#Corr_E <- cov2cor(Sigma_E)
#
#cor(E) - Corr_E
#Sigma_E - cov(E)
#max(abs(cor(E)[row(cor(E)) != col(cor(E))]))
#max(abs(cor(E) - corr_mat_env))
