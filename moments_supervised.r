suppressPackageStartupMessages(library(R.utils))
library(PearsonDS)
library(argparse)
library(moments)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--llr_h1", help = "Input H1 LLR", required = T)
parser$add_argument("--llr_h0", help = "Input H0 LLR", required = T)
parser$add_argument("--moments", help = "Output path to moments", required = T)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

llr0_training= read.table(args$llr_h0, hea=T)$llr
llr1_training= read.table(args$llr_h1, hea=T)$llr
stopifnot(nrow(llr0_training)==nrow(llr1_training))
cat("LLR imported\n")

#------------------------------------------------------------------------------#
# Compute moments
#------------------------------------------------------------------------------#

llr0_moments = c(mean(llr0_training), var(llr0_training), skewness(llr0_training), kurtosis(llr0_training))
llr1_moments = c(mean(llr1_training), var(llr1_training), skewness(llr1_training), kurtosis(llr1_training))
cat("Moments computed\n")

#------------------------------------------------------------------------------#
# Write moments
#------------------------------------------------------------------------------#
cat(llr1_moments, sep='\t', file=args$moments, fill=T)  
cat(llr0_moments, sep='\t', file=args$moments, fill=T, append=T)  
