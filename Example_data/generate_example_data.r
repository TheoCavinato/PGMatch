library(MASS)
library(data.table)

setwd(".")

set.seed(1789)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# input
r2 = c(0.5, 0.4, 0.3, 0.2, 0.1)
n=5*1e2
r=sqrt(r2)
n_pheno = length(r2)
Cg <- cov2cor(crossprod(matrix(rnorm(n_pheno^2), nrow = n_pheno)))
Ce <- cov2cor(crossprod(matrix(rnorm(n_pheno^2), nrow = n_pheno)))

# output
out_pheno_biobank = "Example_data/biobank_phenotypes.tsv"
out_pheno_ind = "Example_data/individual_phenotypes.tsv"
out_pgs_biobank = "Example_data/biobank_pgs.tsv"
out_pgs_ind = "Example_data/genome_pgs.tsv"

#------------------------------------------------------------------------------#
# Simulate phenotypes and PGS
#------------------------------------------------------------------------------#
G = mvrnorm(n+1,mu=rep(0,n_pheno),Sigma=Cg)
E = mvrnorm(n+1,mu=rep(0,n_pheno),Sigma=Ce)
PRS = G%*%diag(r)
X = PRS + E%*%diag(sqrt(1-r2))
X = scale(X)

#------------------------------------------------------------------------------#
# Export data
#------------------------------------------------------------------------------#

# export phenotypes
colnames(X)= paste0("PHENO_", c(1:n_pheno))
X_df = data.table("IID"=c(1:(n+1)))
X_df = cbind(X_df, data.table(X))

X_biobank = X_df[c(1:n),]
X_ind = X_df[(n+1),]

write.table(X_biobank, out_pheno_biobank, quote=F, row.names=F, sep='\t')
write.table(X_ind, out_pheno_ind, quote=F, row.names=F, sep='\t')

# export pgs
colnames(PRS)= paste0("PGS_", c(1:n_pheno))
PRS_df = data.table("IID"=c(1:(n+1)))
PRS_df = cbind(PRS_df, data.table(PRS))

PRS_biobank = PRS_df[c(1:n),]
PRS_ind = PRS_df[(n+1),]

write.table(PRS_biobank, out_pgs_biobank, quote=F, row.names=F, sep='\t')
write.table(PRS_ind, out_pgs_ind, quote=F, row.names=F, sep='\t')