library("PearsonDS")
library("mvtnorm")
library("moments")
library("MASS")
library("argparse")

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--r2", help = "Input r2", required = T)
parser$add_argument("--ce", help = "Input env corr", required = T)
parser$add_argument("--cg", help = "Input pgs corr", required = T)
parser$add_argument("--moments", help = "Output path for moments", required = T)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

r2 = read.table(args$r2,hea=T)$r2
Ce = as.matrix(read.table(args$ce))
Cg = as.matrix(read.table(args$cg))
cat("r2, Ce and Cg imported\n")

#------------------------------------------------------------------------------#
# Derive moments from r2, Ce and Cg
#------------------------------------------------------------------------------#
n=5*1e5
r=sqrt(r2)
n_pheno = length(r2)

G = mvrnorm(n,mu=rep(0,n_pheno),Sigma=Cg)
E = mvrnorm(n,mu=rep(0,n_pheno),Sigma=Ce)
PRS = G%*%diag(r)
X = PRS + E%*%diag(sqrt(1-r2))
X = scale(X)
d1 = (X-PRS)
prm = sample(1:n)
Xr = X[prm,]
d1r = (Xr-PRS)

p0_H0 = dmvnorm(Xr,mean=rep(0,n_pheno),sigma=Ce,log = TRUE)
p0_H1 = dmvnorm(X,mean=rep(0,n_pheno),sigma=Ce,log = TRUE)
p1_H0 = dmvnorm(d1r,mean=rep(0,n_pheno),sigma=diag(sqrt(1-r2))%*%Ce%*%diag(sqrt(1-r2)),log = TRUE)
p1_H1 = dmvnorm(d1,mean=rep(0,n_pheno),sigma=diag(sqrt(1-r2))%*%Ce%*%diag(sqrt(1-r2)),log = TRUE)

llr0_training = p1_H0-p0_H0
llr1_training = p1_H1-p0_H1

# COMPUTE MOMENTS
llr0_moments = c(mean(llr0_training), var(llr0_training), skewness(llr0_training), kurtosis(llr0_training))
llr1_moments = c(mean(llr1_training), var(llr1_training), skewness(llr1_training), kurtosis(llr1_training))
cat("Moments computed\n")

#------------------------------------------------------------------------------#
# Write result
#------------------------------------------------------------------------------#
# output moments in order to plot them at the end
cat(llr1_moments, sep='\t', file=args$moment, fill=T)
cat(llr0_moments, sep='\t', file=args$moment, fill=T, append=T)

