library(data.table)
library(ggplot2)
library(ggpubr)
library(argparse)

# Goal: try to reproduce the results from IDFX as I understand IDFX works

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--pgs_train_p", required = T)
parser$add_argument("--pheno_train_p", required = T)
parser$add_argument("--pgs_test_p", required = T)
parser$add_argument("--pheno_test_p", required = T)

parser$add_argument("--out_png", required = T)
parser$add_argument("--out_probas", required = T)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# 1. Import data and compute LLR
#------------------------------------------------------------------------------#

# import data
training_pgs_df = fread(args$pgs_train_p)
training_pheno_df = fread(args$pheno_train_p)

# remove IID
sub_pheno_df = training_pheno_df[,-1]
sub_pgs_df = training_pgs_df[,-1]

# compute LLR for each phenotype
training_llr_mat = matrix(0, nrow=nrow(sub_pheno_df), ncol=nrow(sub_pheno_df), byrow=F)
all_models=list()
means_h1 = list()
means_h0 = list()
sds_h1 = list()
sds_h0 = list()
for(idx in c(1:ncol(sub_pheno_df))){
	#------------------------------------------------------------------------------#
	# 2. Perform linear regression 
	#------------------------------------------------------------------------------#
	lm_df = data.frame(y=sub_pheno_df[[idx]], x=sub_pgs_df[[idx]])
	lm_model = lm(y ~ x, data=lm_df)
	all_models[[idx]] = lm_model
	
	#------------------------------------------------------------------------------#
	# 3. get residuals
	#------------------------------------------------------------------------------#
	pheno_mat = matrix(sub_pheno_df[[idx]], nrow=nrow(sub_pheno_df), ncol=nrow(sub_pheno_df), byrow=F)
	pgs_mat = matrix(sub_pgs_df[[idx]], nrow=nrow(sub_pgs_df), ncol=nrow(sub_pgs_df), byrow=T)
	predict_mat = matrix(predict(lm_model, data.frame(x=pgs_mat[1,])), nrow=nrow(sub_pheno_df), ncol=nrow(sub_pheno_df), byrow=T)
	residual_mat = pheno_mat - predict_mat
	stopifnot(all(round(diag(residual_mat), 5) ==  round(as.vector(lm_model$residuals), 5)))
	
	#------------------------------------------------------------------------------#
	# 4. Compute LLR
	#------------------------------------------------------------------------------#
	
	mean_h1 = mean(diag(residual_mat))
	sd_h1 = sd(diag(residual_mat))
	mean_h0 = mean(residual_mat[row(residual_mat) != col(residual_mat)])
	sd_h0 = sd(residual_mat[row(residual_mat) != col(residual_mat)])
	means_h1[[idx]] = mean_h1
	means_h0[[idx]] = mean_h0
	sds_h1[[idx]] = sd_h1
	sds_h0[[idx]] = sd_h0
	
	dnorm_h1 = dnorm(residual_mat, mean=mean_h1, sd=sd_h1, log=T)
	dnorm_h0 = dnorm(residual_mat, mean=mean_h0, sd=sd_h0, log=T)
	
	llr_mat = dnorm_h1 - dnorm_h0
	
	training_llr_mat = training_llr_mat + llr_mat
}

cat("Training done.\n")

#------------------------------------------------------------------------------#
# 5. Scale LLR
#------------------------------------------------------------------------------#
scaled_training_llr_mat = t(scale(t(training_llr_mat)))

#------------------------------------------------------------------------------#
# 7. Compute LLR on testing set
#------------------------------------------------------------------------------#

# import testing data
testing_pgs_df = fread(args$pgs_test_p)
testing_pheno_df = fread(args$pheno_test_p)

sub_test_pheno_df = testing_pheno_df[c(1:1000),-1]
sub_test_pgs_df = testing_pgs_df[c(1:1000), -1]
sub_test_pgs_df_h0 = testing_pgs_df[c(2:1000, 1), -1]

llr_test_computation = function(sub_test_pgs_df){
	testing_llr_mat = matrix(0, nrow=nrow(sub_test_pgs_df), ncol=nrow(sub_test_pgs_df)+1, byrow=F)
	for(idx in c(1:ncol(sub_test_pgs_df))){
		pgs_mat = matrix(sub_pgs_df[[idx]], nrow=nrow(sub_pgs_df), ncol=nrow(sub_pgs_df), byrow=T)
		pgs_mat = cbind(pgs_mat, sub_test_pgs_df[[idx]])

		pheno_mat = matrix(sub_test_pheno_df[[idx]], nrow=nrow(pgs_mat), ncol=ncol(pgs_mat), byrow=F)
		predict_mat = matrix(predict(lm_model, data.frame(x=as.vector(pgs_mat))), nrow=nrow(pgs_mat), ncol=ncol(pgs_mat))

		residual_mat = pheno_mat - predict_mat

		dnorm_h1 = dnorm(residual_mat, mean=means_h1[[idx]], sd=sds_h1[[idx]], log=T)
		dnorm_h0 = dnorm(residual_mat, mean=means_h0[[idx]], sd=sds_h0[[idx]], log=T)

		llr_mat = dnorm_h1 - dnorm_h0

		testing_llr_mat = testing_llr_mat + llr_mat
	}
	return(testing_llr_mat)
}

test_mat_h1 = llr_test_computation(sub_test_pgs_df)
test_mat_h0 = llr_test_computation(sub_test_pgs_df_h0)

# scale the thing
scaled_testing_llr_mat_h1 = t(scale(t(test_mat_h1)))
scaled_testing_llr_mat_h0 = t(scale(t(test_mat_h0)))

cat("Testing done.\n")

#------------------------------------------------------------------------------#
# 6. Make plot
#------------------------------------------------------------------------------#

# plot validation that we understood the approach
plot_df_scaled = rbind( data.table(llr=diag(scaled_training_llr_mat), group="H1"),
	data.table(llr=scaled_training_llr_mat[row(scaled_training_llr_mat) != col(scaled_training_llr_mat)], group="H0"))
plot_df_scaled_test = rbind( data.table(llr=scaled_testing_llr_mat_h1[,1001], group="H1"),
	data.table(llr=scaled_testing_llr_mat_h0[,1001], group="H0"))

palette = c("#dd5129", "#43b284")
p = ggplot() +
  geom_density(
    data = plot_df_scaled,
    aes(x = llr, y = after_stat(density), color=group),
    alpha = 0.5
  ) +
geom_density(
    data = plot_df_scaled_test,
    aes(x = llr, y = -after_stat(density), color=group),
    alpha = 0.5
  ) +
  scale_color_manual(values=palette) +
  geom_hline(yintercept = 0) +
  theme_bw() +
  labs(x= "Log-likelihood ratio (LLR)", y="Density", color=NULL,linetype=NULL) +
  theme(legend.position =c(0.7,0.7),
	plot.title = element_text(hjust=0.5))

#ggsave(args$out_png)


#------------------------------------------------------------------------------#
# 7. write probailitiles
#------------------------------------------------------------------------------#

# perform KDE
dens_H1 <- density(subset(plot_df_scaled, group=="H1")$llr)
dens_H0 <- density(sample(subset(plot_df_scaled, group=="H0")$llr, replace=F, 1000))

# compute proba
compute_probas = function(llr_values) {
	predicted_density_H0 <- approx(dens_H0$x, dens_H0$y, llr_values, rule=2)$y
	predicted_density_H1 <- approx(dens_H1$x, dens_H1$y, llr_values, rule=2)$y
	probas_H0 = predicted_density_H0 / (predicted_density_H0 + predicted_density_H1)
	probas_H1 = predicted_density_H1 / (predicted_density_H0 + predicted_density_H1)
	stopifnot(all(round(probas_H0 + probas_H1, 5) == 1))
	cat("Probas computed\n")
	return(probas_H1)
}

test_H1_probas =  compute_probas(subset(plot_df_scaled_test, group=="H1")$llr)
test_H0_probas =  compute_probas(subset(plot_df_scaled_test, group=="H0")$llr)

# output those probabilities
probas_dt = rbind(data.table(proba=test_H1_probas, truth="H1"),
data.table(proba=test_H0_probas, truth="H0"))

fwrite(probas_dt, args$out_probas, sep="\t")
