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



suppressPackageStartupMessages(library(R.utils))
library(data.table)
library(argparse)
library(mvtnorm)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--pheno", help = "Input pheno data frame", required = T)
parser$add_argument("--pgs", help = "Input pgs data frame", required = T)
parser$add_argument("--r2", help="Input var explained for each phenotype", required=T)
parser$add_argument("--ce", help="Input env correlaiton", required=T)
parser$add_argument("--llr", help="Output path to LLR computed", required=T)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import phenos, pgs, r2 and Ce
#------------------------------------------------------------------------------#
merged_pheno_df = fread(args$pheno, hea=T)
merged_pgs_df = fread(args$pgs, hea=T)
r2 = read.table(args$r2, hea=T)$r2
corr_mat_env = as.matrix(fread(args$ce))
n_pheno = length(r2)
stopifnot(nrow(merged_pgs_df$IID)== nrow(merged_pheno_df$IID))
stopifnot(length(r2) == (ncol(merged_pgs_df) - 1))
cat("Phenotypes and PGS imported\n")

#------------------------------------------------------------------------------#
# Quantile normalize phenotypes and pgs
#------------------------------------------------------------------------------#
quantile_norm = function(x){
    norm_dist = rnorm(length(x), mean=0, sd=1)
    ori_order = order(x)
    sorted_dist = x[ori_order]
    sorted_new_dist = sort(norm_dist)
    new_dist = sorted_new_dist[order(ori_order)]
    return(new_dist)
}

merged_pgs_df_scaled = apply(merged_pgs_df[,-c('IID')], 2, quantile_norm)
merged_pheno_df_scaled = apply(merged_pheno_df[,-c('IID')], 2, quantile_norm)

# debugging
#cat(paste( apply(merged_pheno_df_scaled, 2, mean), apply(merged_pheno_df_scaled,2 , sd), apply(merged_pgs_df_scaled, 2, mean) , apply(merged_pgs_df_scaled,2 , sd) ), fill=TRUE, sep='\t')

cat("Data quantile normalized", fill=TRUE)

#------------------------------------------------------------------------------#
# Run LLR
#------------------------------------------------------------------------------#

n_ind = nrow(merged_pgs_df_scaled)
n_pheno = ncol(merged_pgs_df_scaled)

llr_mat = sapply(c(1:n_ind), function(t_idx){
	pheno_t = matrix(rep(merged_pheno_df_scaled[t_idx,], n_ind), nrow=n_ind, byrow=T)
	diff_mat_test = pheno_t - as.matrix(merged_pgs_df_scaled)%*%diag(sqrt(r2))
	p0_test = dmvnorm(pheno_t ,mean=rep(0,n_pheno),sigma=corr_mat_env,log = TRUE)
	p1_test = dmvnorm(diff_mat_test,mean=rep(0,n_pheno),sigma=diag(sqrt(1-r2))%*%corr_mat_env%*%diag(sqrt(1-r2)),log = TRUE)
	llr_test = p1_test  - p0_test
	if(t_idx%%1e3 ==0) {cat(t_idx, "individuals done\n")}
	return(round(llr_test, 4))
})

cat("LLR computed", fill=TRUE)
cat("Mean diag", mean(diag(llr_mat)), "\n")
cat("Mean total", mean(llr_mat), "\n")

#------------------------------------------------------------------------------#
# Write llrs
#------------------------------------------------------------------------------#
colnames(llr_mat) = merged_pheno_df$IID
out_gz = gzfile(args$llr, 'w')
write.table(llr_mat, file=out_gz, row.names=F, quote=F)
close(out_gz)

