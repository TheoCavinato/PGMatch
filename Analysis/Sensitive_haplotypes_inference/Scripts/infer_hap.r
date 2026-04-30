library(data.table)
library(ggpubr)
library(ggplot2)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

args=commandArgs(trailingOnly=T)

met_param=args[1]
param_folder =args[2]
out_tsv=args[3]

# input
n_files  <- 1000
n_rows   <- 100000
hap_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Apoe_inference/All_haplotypes/all_haplotypes.merged.tsv.gz"
pgs_p = paste0(param_folder, "Datasets/pgs.test.sup_scaled.tsv") # just for IID order
#pgs_p ="/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40//Datasets/pgs.test.sup_scaled.tsv" # just for IID order

#------------------------------------------------------------------------------#
# Import haplotypes
#------------------------------------------------------------------------------#

hap_dt = fread(hap_p)
pgs_iids = fread(pgs_p)$IID
hap_dt[, APOE := as.integer(grepl("e4", hap_dt$APOE))]
hap_dt[, ABO := as.integer("OO" == ABO)]
hap_dt[, FUT2 := as.integer(FUT2 >= 1)]
hap_dt[, LCT := as.integer(LCT >= 1)]

hap_x_pgs_ids = subset(hap_dt, IID %in% pgs_iids)[, c("IID", "APOE","ABO","FUT2","LCT","DQB1_602")]

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

idx <- match(pgs_iids, hap_x_pgs_ids$IID)
valid <- !is.na(idx)
hap_aligned <- hap_x_pgs_ids[idx[valid], ]
print(dim(hap_aligned))
hap_aligned = hap_aligned[IID  %in% hap_x_pgs_ids$IID,]
print(dim(hap_aligned))
pheno_mat   = as.matrix(hap_aligned[, -"IID"])        # pure numeric matrix, n x p

for (nbr_ind in seq_len(n_files)) {
  fname <- sprintf("%s/PGMatch_results/proba.%s.test.ind_%d.tsv.gz", param_folder, met_param, nbr_ind)
  dt <- fread(fname, select = c("IID", "Proba"))
  dt$VS_IID = pgs_iids
  dt[nbr_ind, Proba := 0]
  dt = dt[VS_IID %in% hap_aligned$IID,]

  stopifnot(dt$IID[1] == pgs_iids[nbr_ind])
  stopifnot(dt$VS_IID == hap_aligned$IID)

  probas <- dt$Proba
  probas_norm <- probas / sum(probas)
  #merge_dt = merge(dt[-nbr_ind,], hap_x_pgs_ids, by.x="VS_IID", by.y="IID")
  #merge_dt$Proba == probas

  weighted_avg <- as.data.table(round(probas_norm %*% pheno_mat, 5))
  #print(weighted_avg)
  #print(length(merge_dt$Proba / sum(merge_dt$Proba)))
  #print(dim(as.matrix(hap_x_pgs_ids[, -"IID"])))
  #weighted_avg = (merge_dt$Proba / sum(merge_dt$Proba)) %*% as.matrix(hap_x_pgs_ids[-nbr_ind, -"IID"])

  fwrite(weighted_avg, out_tsv, sep="\t", append=(nbr_ind!=1), col.names=(nbr_ind==1))

  if (nbr_ind %% 100 == 0) message("Processed ", nbr_ind, " / ", n_files)
}
# Do validation
#fwrite(final, out_tsv, sep="\t")

