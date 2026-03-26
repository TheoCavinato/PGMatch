suppressPackageStartupMessages(library(R.utils))
library(data.table)
library(argparse)
library(mvtnorm)
library(PearsonDS)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--llr_matrix", help="Input LLR values previously computed", required=T)
parser$add_argument("--round", help="Number of digits to use when writing probabilities", type = "integer", default = 4, required=F)

parser$add_argument("--probas_h0", help="Output file for probabilities", required=T)
parser$add_argument("--probas_h1", help="Output file for probabilities", required=T)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import llr
#------------------------------------------------------------------------------#
llr_matrix = as.matrix(fread(args$llr_matrix, hea=T))
rownames(llr_matrix) = colnames(llr_matrix)

llr_train_matrix = llr_matrix[c(1:1000), c(1:1000)]
llr_test_matrix = llr_matrix[c(1001:2000), c(1001:2000)]
stopifnot(colnames(llr_test_matrix) == rownames(llr_test_matrix))
stopifnot(colnames(llr_train_matrix) == rownames(llr_train_matrix))
stopifnot(!(colnames(llr_train_matrix) %in% rownames(llr_test_matrix)))

scaled_llr_train_matrix = t(scale(t(llr_train_matrix)))
diag_train = diag(scaled_llr_train_matrix)
off_diag_train = c(scaled_llr_train_matrix[lower.tri(scaled_llr_train_matrix)], scaled_llr_train_matrix[upper.tri(scaled_llr_train_matrix)])
cat("Training H1 mean:", mean(diag_train),"\n")
cat("Training H0 mean:", mean(off_diag_train),"\n")

llr_train_vs_test_matrix = llr_matrix[c(1001:2000), c(1:1000)]
diag_test = diag(llr_test_matrix)
off_diag_test = sample(c(llr_test_matrix[lower.tri(llr_test_matrix)], llr_test_matrix[upper.tri(llr_test_matrix)]), 1000,replace=F)
scaled_test_llr_h1 = t(scale(t(cbind(llr_train_vs_test_matrix, diag_test))))[,1001]
scaled_test_llr_h0 = t(scale(t(cbind(llr_train_vs_test_matrix, off_diag_test))))[,1001]
cat("Testing H1 mean:", mean(scaled_test_llr_h1),"\n")
cat("Testing H0 mean:", mean(scaled_test_llr_h0),"\n")

cat("LLR imported and scaled\n")

#------------------------------------------------------------------------------#
# Kernel Density Estimation
#------------------------------------------------------------------------------#

dens_H1 <- density(diag_train)
dens_H0 <- density(off_diag_train)

#------------------------------------------------------------------------------#
# Compute probas
#------------------------------------------------------------------------------#

# COMPUTE PROBA
get_probas = function(llr_test) {
	predicted_density_H0 <- approx(dens_H0$x, dens_H0$y, llr_test, rule=2)$y
	predicted_density_H1 <- approx(dens_H1$x, dens_H1$y, llr_test, rule=2)$y
	probas_H0 = predicted_density_H0 / (predicted_density_H0 + predicted_density_H1)
	probas_H1 = predicted_density_H1 / (predicted_density_H0 + predicted_density_H1)
	stopifnot(all(round(probas_H0 + probas_H1, 5) == 1))
	cat("Probas computed\n")
	return(probas_H1)
}

test_H1_probas_H1 = get_probas(scaled_test_llr_h1)
test_H0_probas_H1 = get_probas(scaled_test_llr_h0)
cat("Mean probas H0:", mean(test_H0_probas_H1), "\n")
cat("Mean probas H1:", mean(test_H1_probas_H1), "\n")

#------------------------------------------------------------------------------#
# Write probabilities
#------------------------------------------------------------------------------#

output_df = data.frame(IID=colnames(llr_test_matrix), Proba=test_H0_probas_H1)
out_gz = gzfile(args$probas_h0, 'w')
cat("Mean probas H0:", mean(output_df$Proba), "\n")
write.table(output_df, file=out_gz, row.names=F, quote=F)
close(out_gz)

output_df = data.frame(IID=colnames(llr_test_matrix), Proba=test_H1_probas_H1)
out_gz = gzfile(args$probas_h1, 'w')
cat("Mean probas H1:", mean(output_df$Proba), "\n")
write.table(output_df, file=out_gz, row.names=F, quote=F)
close(out_gz)
