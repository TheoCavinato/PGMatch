library(ggplot2)

# Using a constant r2 instead of the actual r2 seem to work better
# but why?
# Here I try to address the problme directly thorugh simulations


cat("Simulating data:\n")
r2 = c(0.3529248, 0.3279128, 0.2788137, 0.2584552, 0.2166321, 0.2160767, 0.2069917, 0.1899249, 0.1854733, 0.1600537)
r=sqrt(r2)
n_pheno = length(r2)

G = matrix(rnorm(n * n_pheno, mean = 0, sd = 1), nrow = n, ncol = n_pheno)
E = matrix(rnorm(n * n_pheno, mean = 0, sd = 1), nrow = n, ncol = n_pheno)
PRS =G %*% diag(r)

X = PRS + E %*% diag(sqrt(1-r2))
apply(E %*% diag(sqrt(1-r2)), 2, var) + r2 # should be close to one everywhere
apply(X, 2, var)  # should be close to 1

cat("Computing LLR:\n")
diff_mat = X - PRS
wrong_diff_mat = X - PRS[c(2:nrow(PRS), 1) ]

corr_mat_env = cor(E %*% diag(sqrt(1-r2))) 

p0 = dmvnorm(X,mean=rep(0,n_pheno),sigma=corr_mat_env,log = TRUE)
p1_h0 = dmvnorm(wrong_diff_mat,mean=rep(0,n_pheno),sigma= diag(sqrt(1-r2)) %*% corr_mat_env %*% diag(sqrt(1-r2)),log = TRUE)
p1_h1 = dmvnorm(diff_mat ,mean=rep(0,n_pheno),sigma= diag(sqrt(1-r2)) %*% corr_mat_env %*% diag(sqrt(1-r2)),log = TRUE)

llr_h1 = p1_h1 - p0
llr_h0 = p1_h0 - p0

cat("Plot result:\n")
plot_df = rbind(data.frame(llr=llr_h1, group="H1"), data.frame(llr=llr_h0, group="H0"))
p = ggplot(plot_df, aes(llr)) +
	geom_density()

ggsave()


