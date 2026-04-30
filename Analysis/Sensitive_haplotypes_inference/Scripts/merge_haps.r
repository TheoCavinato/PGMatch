library(data.table)


#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

args=commandArgs(trailingOnly=T)

# input
hap_folder = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Haplotypes/"
apoe_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Apoe_inference//APOE_status/apoe_status.per_ind.txt"

# output
out_tsv = args[1]

#------------------------------------------------------------------------------#
# Import all haplotypes
#------------------------------------------------------------------------------#

abo_dt = fread(paste0(hap_folder, "abo_reformat.snp"))
fut2_dt = fread(paste0(hap_folder, "fut2.snp.raw"))
lct_dt = fread(paste0(hap_folder, "lct.snp.raw"))

apoe_dt = fread(apoe_p)
names(apoe_dt) = c("IID", "APOE")
hla_dt = fread(paste0(hap_folder, "hla_mat.tsv"))

sum(is.na(lct_dt[[ncol(lct_dt)]]))
sum(is.na(fut2_dt[[ncol(fut2_dt)]]))
sum(is.na(abo_dt[[ncol(abo_dt)]]))

#------------------------------------------------------------------------------#
# Merge data
#------------------------------------------------------------------------------#

# merge haplotypes from imputed genotypes
ncol_abo = ncol(abo_dt)
ncol_lct = ncol(lct_dt)
ncol_fut2 = ncol(fut2_dt)

sub_abo_dt = abo_dt[, c(1,..ncol_abo)]
names(sub_abo_dt) = c("IID", "ABO")
sub_fut2_dt = fut2_dt[, c(2,..ncol_fut2)]
names(sub_fut2_dt) = c("IID", "FUT2")
sub_lct_dt = lct_dt[, c(2,..ncol_lct)]
names(sub_lct_dt) = c("IID", "LCT")

haplo_merge = merge(apoe_dt,
merge(sub_abo_dt,
merge( sub_fut2_dt,
	sub_lct_dt,
	by="IID"),
	by="IID"),
	by="IID")

# merge HLA haplotypes
final_merge = merge(haplo_merge,hla_dt,  by="IID")

#------------------------------------------------------------------------------#
# Write output
#------------------------------------------------------------------------------#

# write output
fwrite(final_merge, out_tsv, sep="\t")
