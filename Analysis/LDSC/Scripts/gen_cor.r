library(GenomicSEM)
library(data.table)
library(argparse)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
# input
parser$add_argument("--path_to_ld_matrices", required=T)
parser$add_argument("--input_p", required=T)
# output
parser$add_argument("--out_dir", required=T)
parser$add_argument("--out_s", required=T)
parser$add_argument("--out_v", required=T)
parser$add_argument("--out_i", required=T)
parser$add_argument("--out_s_stand", required=T)
parser$add_argument("--out_v_stand", required=T)
args <- parser$parse_args()

setwd(args$out_dir)

# debuging
#args$path_to_ld_matrices = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/LDSC//eur_w_ld_chr"
#args$input_p = "test.txt"

#------------------------------------------------------------------------------#
# Import ld matrices
#------------------------------------------------------------------------------#

# get information about files
input_dt = fread(args$input_p, hea=T)
trait_names = input_dt$PHENO
sumstat_files = input_dt$PATH

# get covariance matrix 
sample_prev = rep(NA, nrow(input_dt))
pop_prev = rep(NA, nrow(input_dt))
ldsc.covstruct <- ldsc(traits = sumstat_files,
			sample.prev = sample_prev, 
                       population.prev = pop_prev,
			ld = args$path_to_ld_matrices,
                       wld = args$path_to_ld_matrices,
			trait.names = trait_names,
			stand=T) # get standardized covariance matrix to directly read correlation


cat("ldsc performed!\n")

# write output
write_output = function(out, data){
	rownames(data) = colnames(data)
	write.table(data, out, sep='\t', quote=F)
}

write_output(args$out_s, ldsc.covstruct$S)
write_output(args$out_v, ldsc.covstruct$V)
write_output(args$out_i, ldsc.covstruct$I)
write_output(args$out_s_stand, ldsc.covstruct$S_Stand)
write_output(args$out_v_stand, ldsc.covstruct$V_Stand)
