library(data.table)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

#args = commandArgs(trailingOnly=T)
#
## input
#gwas_file <- args[1]
#
## ouptut
#out_new = args[2]
#
#cat("GWAS", gwas_file, "\n")
#cat("NEW GWAS", out_new, "\n")

parser <- ArgumentParser()
parser$add_argument("--gwas_file", required=T)
parser$add_argument("--out_new", required=T)
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Modify and save
#------------------------------------------------------------------------------#

# change -log10p to p, and modify header tant qu'on y est
gwas_dt = fread(args$gwas_file, hea=T, select = c("ID", "CHROM", "GENPOS","ALLELE1", "ALLELE0", "BETA", "SE", "LOG10P", "N"))
gwas_dt$LOG10P = 10^(-gwas_dt$LOG10P)
names(gwas_dt) = c("SNP","chr","pos","A1","A2","b","se","p","N")
stopifnot(length(unique(gwas_dt$N)) == 1)
N = gwas_dt$N[1]

# write output
g_out = gzfile(args$out_new, "w")
write.table(gwas_dt, g_out, sep='\t', quote=F, row.names=F)
close(g_out)
