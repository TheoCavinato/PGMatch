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
parser$add_argument("--llr_test", help="Input LLR to test", required=T)
parser$add_argument("--llr_h0", help="Input H0 LLR (from training)", required=T)
parser$add_argument("--llr_h1", help="Input H1 LLR (from training)", required=T)
parser$add_argument("--probas", help="Output file for probabilities", required=T)
parser$add_argument("--round", help="Number of digits to use when writing probabilities", type = "integer", default = 4, required=F)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import llr
#------------------------------------------------------------------------------#
llr_testing= fread(args$llr_test, hea=T)

llr0_training= read.table(args$llr_h0, hea=T)
llr1_training= read.table(args$llr_h1, hea=T)
cat("LLR imported\n")

#------------------------------------------------------------------------------#
# Kernel Density Estimation
#------------------------------------------------------------------------------#
dens_H0 <- density(llr0_training$llr) 
dens_H1 <- density(llr1_training$llr) 

#------------------------------------------------------------------------------#
# Compute probas
#------------------------------------------------------------------------------#

# COMPUTE PROBA
# NOTE: NEED TO ADD THE CASE WHERE THE DATA IS COMING FROM llr_computation_all_vs_all.r
predicted_density_H0 <- approx(dens_H0$x, dens_H0$y, llr_testing$llr, rule=2)$y
predicted_density_H1 <- approx(dens_H1$x, dens_H1$y, llr_testing$llr, rule=2)$y
probas_H0 = predicted_density_H0 / (predicted_density_H0 + predicted_density_H1)
probas_H1 = predicted_density_H1 / (predicted_density_H0 + predicted_density_H1)
stopifnot(all(round(probas_H0 + probas_H1, 5) == 1))
cat("Probas computed\n")

#------------------------------------------------------------------------------#
# Write probabilities
#------------------------------------------------------------------------------#

output_df = data.frame(IID=llr_testing[,"IID"], Proba=probas_H1)
cat("Mean proba :",mean(output_df$Proba),"\n")
out_gz = gzfile(args$probas, 'w')
write.table(output_df, file=out_gz, row.names=F, quote=F)
close(out_gz)
