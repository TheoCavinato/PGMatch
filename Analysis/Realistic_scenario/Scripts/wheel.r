library(argparse)
library(data.table)

# The idea is to generate datasets that would generate enough mismatches for the comparison
#to do so ,we "turn the wheel", i.e. we shift the positions of the individuals
#by X steps

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--pgs_p", required=T)
parser$add_argument("--idx", required=T, type="integer")
# output
parser$add_argument("--out_pgs", required=T)
args <- parser$parse_args()

#args$pgs_p = "/scratch/tcavinat/Phenotype_inference_attack/Realistic_scenario/Analysis.NBR_PHENO_2.N_TEST_100000.N_TRAIN_1000/itr_1/Datasets/pgs.test.h0.tsv.gz"
#args$idx = 2

#------------------------------------------------------------------------------#
# Import the file and make the wheel turn
#------------------------------------------------------------------------------#

pgs_df = fread(args$pgs_p)

n = nrow(pgs_df)
first_rows = c((n-args$idx) : n)
last_rows = c(1:(n-args$idx-1))
rows = c(first_rows, last_rows)
wheeled_pgs_df = pgs_df[rows, ]

#------------------------------------------------------------------------------#
# Write the file
#------------------------------------------------------------------------------#

out_gz = gzfile(args$out_pgs, "w")
write.table(wheeled_pgs_df, file=out_gz, row.names=F, quote=F)
close(out_gz)

