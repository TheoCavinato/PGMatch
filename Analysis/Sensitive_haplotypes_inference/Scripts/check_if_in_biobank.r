library(data.table)
library(ggpubr)
library(ggplot2)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# input
n_files  <- 1000
n_rows   <- 100000

args=commandArgs(trailingOnly=T)

#proba_h1_scaled_p = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40//PGMatch_results/proba.sup_scaled.test.H1.tsv.gz"
#proba_h1_p  = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40//PGMatch_results/proba.sup.test.H1.tsv.gz"
#llr_h1_p = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40//PGMatch_results/llr.sup.test.H1.tsv.gz"
#llr_h1_scaled_p = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40//PGMatch_results/llr.sup.test.sup_scaled.H1.tsv.gz"
proba_h1_scaled_p = args[1]
proba_h1_p  = args[2]
llr_h1_p = args[3]
llr_h1_scaled_p = args[4]

# output
out_pdf = args[5]

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

results <- vector("list", n_files)

match_probas = c()
for (nbr_ind in seq_len(n_files)) {

  #fname <- sprintf("/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/PGMatch_results/proba.sup.test.ind_%d.tsv.gz", nbr_ind)
  fname <- sprintf("/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Plot_data/Sensitive_haplotypes_inference/PGMatch_results/proba.sup.test.ind_%d.tsv.gz", nbr_ind)

  dt    <- fread(fname)          # columns: IID, proba

  total_sum <- sum(dt$Proba)

  # 1. Sum of all proba EXCEPT the row whose index == nbr_ind
  sum_excl_ind <- total_sum - dt$Proba[nbr_ind]
  max_excl_ind = max(dt$Proba[-nbr_ind])
  match_probas = c(match_probas, dt$Proba[nbr_ind])

  # 2. Sum of all proba EXCEPT one randomly chosen proba
  rand_idx        <- sample(setdiff(seq_len(nrow(dt)), nbr_ind), 1L)
  sum_excl_random <- total_sum - dt$Proba[rand_idx]
  max_excl_rand = max(dt$Proba[-rand_idx])

  results[[nbr_ind]] <- data.table(
    nbr_ind         = nbr_ind,
    IID             = dt$IID[1L],          # unique IID for this file
    sum_excl_ind    = sum_excl_ind,
    max_excl_ind = max_excl_ind,
    rand_idx        = rand_idx,
    sum_excl_random = sum_excl_random,
    max_excl_random = max_excl_rand
  )

  if (nbr_ind %% 100 == 0) message("Processed ", nbr_ind, " / ", n_files)
}

final <- rbindlist(results)

#fwrite(final, "results_proba.tsv", sep = "\t")
#message("Done. Results written to results_proba.tsv")

# Do validation
proba_h1_scaled_dt = fread(proba_h1_scaled_p)
stopifnot(match_probas == proba_h1_scaled_dt$Proba[1:1000])

#------------------------------------------------------------------------------#
# Plot data
#------------------------------------------------------------------------------#

message("Median diff in the two scenario for mean:")
message(median(final$sum_excl_ind / n_rows))
message(median(final$sum_excl_random / n_rows))
message(median(final$sum_excl_ind / n_rows ) -  median(final$sum_excl_random / n_rows))

message("Median diff in the two scenario for max:")
message(median(final$max_excl_ind ))
message(median(final$max_excl_random ))
message(median(final$max_excl_ind ) -  median(final$max_excl_random ))

plot_df = rbind(data.table( mean_final = final$sum_excl_ind / n_rows, group="Target not in Biobank"),
	data.table( mean_final = final$sum_excl_random / n_rows, group="Target in Biobank"))

max_df = rbind(data.table( max_final = final$max_excl_ind , group="Target not in Biobank"),
	data.table( max_final = final$max_excl_random , group="Target in Biobank"))

p_mean = ggplot(plot_df, aes(x=as.factor(group), y=mean_final)) +
	geom_violin(fill="grey") +
	geom_boxplot(outlier.shape = NA) +
	labs(x = "", y="Mean of the matching probabilities") +
	theme_bw()

p_max = ggplot(max_df, aes(x=as.factor(group), y=max_final)) +
	geom_violin(fill="grey") +
	geom_boxplot(outlier.shape = NA) +
	labs(x = "", y="Maximum of the matching probabilities")+
	theme_bw()

p_final = ggarrange(p_mean, p_max, ncol=2, labels="AUTO")

ggsave(out_pdf, width=10, height=5)
