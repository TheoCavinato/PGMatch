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
