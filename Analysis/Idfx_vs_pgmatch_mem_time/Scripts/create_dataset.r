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
parser$add_argument("--n_pheno", help = "Number of phenotypes", required = T, type="integer")
parser$add_argument("--n_train", help = "n train", required = T, type="integer")
parser$add_argument("--n_test", help = "n test", required = T, type="integer")

# output
parser$add_argument("--pheno_test", help = "Output path", required = T)
parser$add_argument("--pheno_train", help = "Output path", required = T)
parser$add_argument("--pgs_train_h0", help = "Output path", required = T)
parser$add_argument("--pgs_test_h0", help = "Output path", required = T)
parser$add_argument("--pgs_train_h1", help = "Output path", required = T)
parser$add_argument("--pgs_test_h1", help = "Output path", required = T)

# Parse the args
args <- parser$parse_args()

# debugging
#args$r2="/scratch/tcavinat/Phenotype_inference_attack/Playground//Dataset//r2.nbr_pheno_10.txt"
#args$pheno_test="/scratch/tcavinat/Phenotype_inference_attack/Playground//Dataset//pheno_test.test.tsv.gz"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

r2 = rep(0.1, args$n_pheno)
print(r2)
cat("r2, Ce and Cg imported\n")

#------------------------------------------------------------------------------#
# Create correlation matrices
#------------------------------------------------------------------------------#

n_pheno = args$n_pheno
Ce = diag(n_pheno)
Cg = diag(n_pheno)

#------------------------------------------------------------------------------#
# Simulate data
#------------------------------------------------------------------------------#
n_train = args$n_train
n_test = args$n_test
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
