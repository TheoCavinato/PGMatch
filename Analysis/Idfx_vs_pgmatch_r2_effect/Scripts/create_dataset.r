library("mvtnorm")
library("moments")
library("MASS")
library("Matrix")
library("argparse")
library("data.table")

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
# input
parser$add_argument("--r2", help = "Variance explained between individuals", required = T)
parser$add_argument("--pheno_test", help = "Input path", required = T)
parser$add_argument("--pheno_train", help = "Input path", required = T)
parser$add_argument("--min_corr_ce", required = T, type="double")
parser$add_argument("--max_corr_ce", required = T, type="double")
parser$add_argument("--min_corr_cg", required = T, type="double")
parser$add_argument("--max_corr_cg", required = T, type="double")

# output
parser$add_argument("--pgs_train_h0", help = "Output path", required = T)
parser$add_argument("--pgs_test_h0", help = "Output path", required = T)
parser$add_argument("--pgs_train_h1", help = "Output path", required = T)
parser$add_argument("--pgs_test_h1", help = "Output path", required = T)
parser$add_argument("--ce", help = "Output path", required = T)
parser$add_argument("--cg", help = "Output path", required = T)

# Parse the args
args <- parser$parse_args()

# debugging
#args$r2="/scratch/tcavinat/Phenotype_inference_attack/Playground//Dataset//r2.nbr_pheno_10.txt"
#args$pheno_test="/scratch/tcavinat/Phenotype_inference_attack/Playground//Dataset//pheno_test.test.tsv.gz"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

r2 = read.table(args$r2,hea=T, sep='\t')$r2
print(r2)
cat("r2, Ce and Cg imported\n")

#------------------------------------------------------------------------------#
# Create correlation matrices
#------------------------------------------------------------------------------#

generate_random_corr <- function(n_vars, min_corr, max_corr) {
  # Start with identity
  Sigma <- diag(n_vars)
  
  # Fill lower triangle with random correlations
  for(i in 2:n_vars) {
    for(j in 1:(i-1)) {
      r <- runif(1, min = min_corr, max = max_corr)
      Sigma[i,j] <- r
      Sigma[j,i] <- r  # symmetric
    }
  }
  
    # Force positive definite AND keep it a correlation matrix
	Sigma <- as.matrix(nearPD(Sigma, corr = TRUE)$mat)
  
  return(Sigma)
}

n_pheno = length(r2)
Ce = generate_random_corr(n_pheno, args$min_corr_ce, args$max_corr_ce)
Cg = generate_random_corr(n_pheno, args$min_corr_cg, args$max_corr_cg)
fwrite(Ce, args$ce, sep="\t", col.names=F)
fwrite(Cg, args$cg, sep="\t", col.names=F)

#------------------------------------------------------------------------------#
# Simulate data
#------------------------------------------------------------------------------#
n_train = 1e3
n_test = 1e3
n=n_train + n_test
r=sqrt(r2)

G = mvrnorm(n,mu=rep(0,n_pheno),Sigma=Cg)
E = mvrnorm(n,mu=rep(0,n_pheno),Sigma=Ce)
PRS = G%*%diag(r)
X = PRS + E%*%diag(sqrt(1-r2))
X = scale(X)
cat("Data simulated\n")

#------------------------------------------------------------------------------#
# Format data
#------------------------------------------------------------------------------#

colnames(X) = paste0("PHENO_",c(1:n_pheno))
colnames(PRS) = paste0("PGS_",c(1:n_pheno))

pheno_dt = cbind(data.table(IID=c(1:n)), X)
pgs_dt = cbind(data.table(IID=c(1:n)), PRS)
rand_ids = sample(c(1:n), replace=F)
shuf_pheno_dt = pheno_dt[rand_ids, ]
shuf_pgs_dt = pgs_dt[rand_ids, ]

pheno_train = shuf_pheno_dt[c(1:n_train),]
pheno_test = shuf_pheno_dt[c((n_train+1):(n_train+n_test)),]

pgs_train_h1 = shuf_pgs_dt[c(1:n_train),]
pgs_train_h0 = shuf_pgs_dt[c(2:n_train,1),]
pgs_test_h1 = shuf_pgs_dt[c((n_train+1):(n_train+n_test)),]
pgs_test_h0 = shuf_pgs_dt[c((n_train+2):(n_train+n_test),(n_train+1)),]
cat("Data formated\n")

#------------------------------------------------------------------------------#
# Write data
#------------------------------------------------------------------------------#

fwrite(pheno_test, args$pheno_test, sep="\t")
fwrite(pheno_train, args$pheno_train, sep="\t")

fwrite(pgs_test_h0, args$pgs_test_h0, sep="\t")
fwrite(pgs_test_h1, args$pgs_test_h1, sep="\t")
fwrite(pgs_train_h0, args$pgs_train_h0, sep="\t")
fwrite(pgs_train_h1, args$pgs_train_h1, sep="\t")
cat("Data written\n")
