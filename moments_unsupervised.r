#Copyright (C) 2023-2024 Théo Cavinato
#
#MIT Licence
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.



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

r2 = read.table(args$r2,hea=T, sep='\t')$r2
Ce = as.matrix(read.table(args$ce), sep='\t')
Cg = as.matrix(read.table(args$cg), sep='\t')
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

