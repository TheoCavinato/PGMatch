library(argparse)
library(data.table)

# I want to basically compute proba udsing idfx distributions
# So he  most logic think to do is to convert the LLR into a matrix of my LLR
# and the ngive it to the llr2proba_kde script

# Convert L

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
parser$add_argument("--llr_idfx", required=T)
parser$add_argument("--h1_iids", required=T, type="character")
parser$add_argument("--h0_iids", required=T, type="character")

parser$add_argument("--llr_h0", required=T)
parser$add_argument("--llr_h1", required=T)
args <- parser$parse_args()

h1_iids <- strsplit(args$h1_iids, ",")[[1]]
h0_iids <- strsplit(args$h0_iids, ",")[[1]]
#------------------------------------------------------------------------------#
# Import dat
#------------------------------------------------------------------------------#

idfx_llr = readRDS(args$llr_idfx)
stopifnot(all(colnames(idfx_llr) %in% h1_iids))
stopifnot(all(colnames(idfx_llr) %in% h0_iids))

# subset 
idfx_llr_h1 = idfx_llr[h1_iids, h1_iids]
idfx_llr_h0 = idfx_llr[h1_iids, h0_iids]

#------------------------------------------------------------------------------#
# Write result
#------------------------------------------------------------------------------#

fwrite(data.table(IID = rownames(idfx_llr_h0), llr= diag(idfx_llr_h0)), args$llr_h0, sep="\t")
fwrite(data.table(IID = rownames(idfx_llr_h1), llr= diag(idfx_llr_h1)), args$llr_h1, sep="\t")
