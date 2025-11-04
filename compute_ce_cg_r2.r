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
library(argparse)
library(data.table)
library(corpcor)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--pheno", help = "Input pheno data frame", required = T)
parser$add_argument("--pgs", help = "Input pgs data frame", required = T)
parser$add_argument("--ce", help="Output path for env correlation", required=T)
parser$add_argument("--cg", help="Output path for pgs correlation", required=T)
parser$add_argument("--r2", help="Output path to var explained for each phenotype", required=T)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import phenos and pgs
#------------------------------------------------------------------------------#
merged_pheno_df = fread(args$pheno, hea=T)
merged_pgs_df = fread(args$pgs, hea=T)
stopifnot(identical(merged_pgs_df$IID, merged_pheno_df$IID))

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

# uncomment for debugging
#cat(paste( apply(merged_pheno_df_scaled, 2, mean), apply(merged_pheno_df_scaled,2 , sd), apply(merged_pgs_df_scaled, 2, mean) , apply(merged_pgs_df_scaled,2 , sd) ), fill=TRUE, sep='\t')

cat("Data quantile normalized", fill=TRUE)

#------------------------------------------------------------------------------#
# Compute variance explained on the filtered data
#------------------------------------------------------------------------------#

stopifnot(ncol(merged_pgs_df_scaled) == ncol(merged_pheno_df_scaled))
r2 <- sapply(1:ncol(merged_pgs_df_scaled), function(i) cor(merged_pgs_df_scaled[, i], merged_pheno_df_scaled[, i], use="pairwise.complete.obs")^2)
cat("variance explained computed", fill=TRUE)

#------------------------------------------------------------------------------#
# Compute correlation between phenotypes
#------------------------------------------------------------------------------#
corr_mat = cor(merged_pheno_df_scaled, use="pairwise.complete.obs") # get C
corr_mat_pgs = cor(merged_pgs_df_scaled, use="pairwise.complete.obs") # get Cg
corr_mat_env = cov2cor(cov(merged_pheno_df_scaled) - cov(as.matrix(merged_pgs_df_scaled)%*%diag(sqrt(r2)))) # get Ce
corr_mat_env=make.positive.definite(corr_mat_env, tol=1e-3)
cat("correlation computed", fill=TRUE)

#------------------------------------------------------------------------------#
# Write output
#------------------------------------------------------------------------------#
write_corr = function(df, out_p){
	out_gz = gzfile(out_p, 'w')
	write.table(df, file=out_gz, row.names=F, quote=F, col.names=F, sep="\t")
	close(out_gz)
}
write_corr(corr_mat_env, args$ce)
write_corr(corr_mat_pgs, args$cg)

out_gz = gzfile(args$r2, 'w')
output_df = data.frame(pheno=colnames(merged_pheno_df_scaled) , r2 = r2)
write.table(output_df, file=out_gz, row.names=F, quote=F, sep='\t')
close(out_gz)

