library(GenomicSEM)
library(data.table)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#


parser <- ArgumentParser()
parser$add_argument("--out_dir", required=T)
parser$add_argument("--gwas_files", required=T)
parser$add_argument("--hm3", required=T)
parser$add_argument("--trait_name", required=T)
parser$add_argument("--N", required=T, type="integer")
args <- parser$parse_args()

setwd(args$out_dir)

#------------------------------------------------------------------------------#
# import data
#------------------------------------------------------------------------------#

munge(files = args$gwas_files, hm3 = args$hm3, trait.names=args$trait_name, N = args$N)
