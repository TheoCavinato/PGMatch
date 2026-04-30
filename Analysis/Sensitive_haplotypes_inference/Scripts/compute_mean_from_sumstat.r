library(data.table)
library(Matrix)

args=commandArgs(trailingOnly=T)

message(args[1])
message(args[2])
pheno_id = args[1]

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# input
regenie_p = paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/rhofmeis/projects/AM_v2/Out/Regenie/ukb.subset_150k.",pheno_id,"_regenie.gz")
ldpred_p = paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Compute_polygenic_scores/LDpred2_150K/LDpred_betas/",pheno_id,".betas.tsv.gz")
work_ld="/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/LDpred2/"
map_p = paste0(work_ld, "Data/map_hm3_plus.rds") # use hapmap+


#pgs_p = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/Datasets/pgs.test.tsv.gz"
pgs_p=paste0("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Compute_polygenic_scores/LDpred2_150K/PGS_calc/pheno_",pheno_id,"/score/aggregated_scores.txt.gz")

# output
output_p = args[2]

#------------------------------------------------------------------------------#
# Improt data
#------------------------------------------------------------------------------#
info = readRDS(map_p)

regenie_dt = fread(regenie_p)
ldpred_dt = fread(ldpred_p)

pgs_dt = fread(pgs_p)

# merge data to get ldpred2 effect and regenie AF
merge_dt = merge(regenie_dt, ldpred_dt, by.x = "ID", by.y="rsID")
stopifnot(merge_dt$CHROM == merge_dt$chr_name)
stopifnot(merge_dt$GENPOS == merge_dt$chr_position)
stopifnot(merge_dt$effect_allele == merge_dt$ALLELE1)

#------------------------------------------------------------------------------#
# Compute mean
#------------------------------------------------------------------------------#

expected_mean = sum(merge_dt$A1FREQ * 2 *merge_dt$effect_weight)
message("Expected mean: ", expected_mean)
message("Actual mean: ", mean(pgs_dt[[4]]))

#------------------------------------------------------------------------------#
# Compute variance
#------------------------------------------------------------------------------#

final_expected_var = 0.0
for(curr_chr in c(22:1)){

# import correlation matrix for the CHR
ld_p = paste0(work_ld, "Data/ldref_plus/LD_with_blocks_chr", curr_chr,".rds") # use the hapmap + LD
corr0 <- readRDS(ld_p)  # Load precomputed LD matrix

# downsample info and merge dt to the CHR
sub_info = subset(info, chr==curr_chr)
sub_info$chr_pos_ref_alt = paste(sub_info$chr, sub_info$pos, sub_info$a0, sub_info$a1, sep=":") 
stopifnot(nrow(corr0) == nrow(sub_info))
rownames(corr0) = sub_info$chr_pos_ref_alt
colnames(corr0) = sub_info$chr_pos_ref_alt

sub_merge_dt = subset(merge_dt, CHROM==curr_chr)
sub_merge_dt$chr_pos_ref_alt = paste(sub_merge_dt$CHROM, sub_merge_dt$GENPOS, sub_merge_dt$ALLELE1, sub_merge_dt$ALLELE0, sep=":") 
sub_merge_dt= sub_merge_dt[!duplicated(sub_merge_dt$chr_pos_ref_alt),]

# only keep snps present in both merge dt and sub info
stopifnot(sum(sub_info$chr_pos_ref_alt %in% sub_merge_dt$chr_pos_ref_alt_rev) == 0)
info_x_effect = merge(sub_merge_dt, sub_info, by="chr_pos_ref_alt")

# drop rows and cols in corr0
info_x_effect_sorted <- info_x_effect[order(match(info_x_effect$chr_pos_ref_alt, colnames(corr0))), ]
down_idx = which(colnames(corr0) %in% info_x_effect_sorted$chr_pos_ref_alt)
down_corr0 = corr0[down_idx, down_idx]

p = info_x_effect_sorted$A1FREQ
var <- 2 * p * (1 - p)
sigma <- sqrt(var)
beta_tilde <- info_x_effect_sorted$effect_weight * sigma
var_S <- as.numeric(t(beta_tilde) %*% (down_corr0 %*% beta_tilde))
message("Chromosome ",curr_chr, " : ", var_S)
final_expected_var = final_expected_var + var_S
}

cat(pheno_id, expected_mean, mean(pgs_dt[[4]]), final_expected_var, var(pgs_dt[[4]]), fill=T,file=output_p)
