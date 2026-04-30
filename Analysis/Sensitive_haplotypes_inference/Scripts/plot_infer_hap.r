library(data.table)
library(ggpubr)
library(ggplot2)
library(PRROC)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# input
work_folder = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Plot_data/Sensitive_haplotypes_inference/"
hap_ori_p   = paste0(work_folder, "all_haplotypes.merged.tsv.gz")

n_itr       = 100

pdf_folder  = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Plots/"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

hap_ori_dt = fread(hap_ori_p)[, c("IID", "APOE","ABO","FUT2","LCT","DQB1_602")]
hap_ori_dt[, APOE    := factor(as.integer(grepl("e4", hap_ori_dt$APOE)),  levels = c(0,1))]
hap_ori_dt[, ABO     := factor(as.integer("OO" == ABO),                   levels = c(0,1))]
hap_ori_dt[, FUT2    := factor(as.integer(FUT2 >= 1),                     levels = c(0,1))]
hap_ori_dt[, LCT     := factor(as.integer(LCT  >= 1),                     levels = c(0,1))]
hap_ori_dt[, DQB1_602 := factor(as.integer(DQB1_602 >= 1),                levels = c(0,1))]


# Helper: load one iteration's inference files and merge with ground truth
load_itr = function(itr_nbr) {
	iid_p = paste0(work_folder, "pgs.test.sup_scaled.tsv")
	sup_dt   = fread(sprintf("%s/hap_inf.sup.itr_%s.tsv.gz", work_folder, itr_nbr))
	unsup_dt   = fread(sprintf("%s/hap_inf.unsup.itr_%s.tsv.gz", work_folder, itr_nbr))

	iids     = fread(sprintf("%s/hap_inf.iid.itr_%s.tsv.gz", work_folder, itr_nbr))$IID[1:1000]

	sup_dt$IID   = iids
	unsup_dt$IID = iids
	stopifnot(ncol(sup_dt)   == ncol(hap_ori_dt))
	stopifnot(ncol(unsup_dt) == ncol(hap_ori_dt))
	list(
	sup   = merge(sup_dt,   hap_ori_dt, by = "IID", suffixes = c("_inf", "_ori")),
	unsup = merge(unsup_dt, hap_ori_dt, by = "IID", suffixes = c("_inf", "_ori"))
	)
}

# Load iteration 1 for violin plots
itr1 = load_itr(1)
merge_sup_dt   = itr1$sup
merge_unsup_dt = itr1$unsup

# Load all iterations for PR curves
all_itrs = lapply(seq_len(n_itr), function(i) {
  message("Loading iteration ", i)
  load_itr(i)
})

#------------------------------------------------------------------------------#
# Plot functions
#------------------------------------------------------------------------------#

# Violin plot (unchanged, uses only iteration 1)
violin_plot = function(df, cur_title, haplotype = "APOE") {
  ori_col <- paste0(haplotype, "_ori")
  inf_col <- paste0(haplotype, "_inf")

  stat.test <- compare_means(
    as.formula(paste0(inf_col, " ~ ", ori_col)),
    df,
    method      = "t.test",
    alternative = "greater"
  )
  stat.test$y.position <- max(df[[inf_col]], na.rm = TRUE) * 1.05

  p = ggplot(df, aes(x = as.factor(.data[[ori_col]]), y = .data[[inf_col]])) +
    geom_violin(fill = "grey") +
    geom_boxplot(outlier.shape = NA) +
    stat_pvalue_manual(stat.test, label = "p.format") +
    theme_bw() +
    labs(title = cur_title, x = "") +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))

    if(haplotype!="APOE")  p = p + scale_x_discrete(labels = c("0" = "carriers", "1"="non-carriers")) + ylab(paste0("Pr(",haplotype,")"))
    else  p = p + scale_x_discrete(labels = c( "0" = bquote(epsilon[4] ~ "non-carriers"), "1" = bquote(epsilon[4] ~ "carriers"))) + ylab(expression(Pr(APOE-epsilon[4]))) 
  return(p)
}

precrec_plot = function(all_itrs, cur_title, haplotype = "APOE", method = "sup", conf = 0.95) {
  ori_col <- paste0(haplotype, "_ori")
  inf_col <- paste0(haplotype, "_inf")

  recall_grid <- seq(0, 1, length.out = 200)
  prec_mat    <- matrix(NA, nrow = n_itr, ncol = length(recall_grid))

  for (i in seq_len(n_itr)) {
    df <- all_itrs[[i]][[method]]
    if (length(unique(df[[ori_col]])) < 2) next

    pr <- tryCatch(
      pr.curve(
        scores.class1 = subset(df, df[[ori_col]] == 0)[[inf_col]],
        scores.class0 = subset(df, df[[ori_col]] == 1)[[inf_col]],
        curve = TRUE),
      error = function(e) NULL)

    if (is.null(pr)) next

    curve_df <- as.data.frame(pr$curve)
    colnames(curve_df) <- c("Recall", "Precision", "Threshold")

    prec_mat[i, ] <- approx(
      x    = curve_df$Recall,
      y    = curve_df$Precision,
      xout = recall_grid,
      rule = 2)$y
  }

  alpha <- 1 - conf
  mean_df <- data.frame(
    Recall    = recall_grid,
    Precision = colMeans(prec_mat, na.rm = TRUE),
    lower     = apply(prec_mat, 2, quantile, probs = alpha/2,     na.rm = TRUE),
    upper     = apply(prec_mat, 2, quantile, probs = 1 - alpha/2, na.rm = TRUE)
  )

  p <- ggplot(mean_df, aes(x = Recall, y = Precision)) +
    geom_ribbon(aes(ymin = lower, ymax = upper),
                fill = "steelblue", alpha = 0.3) +
    geom_line(colour = "darkblue", linewidth = 1.1) +
    theme_bw() +
    xlim(0, 1) +
    ylim(0, 1) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold")) +
    labs(title = cur_title)

  return(p)
}


#------------------------------------------------------------------------------#
# Per-haplotype figure
#------------------------------------------------------------------------------#

plot_haplotype = function(cur_hap) {
  p_violin_sup    = violin_plot(merge_sup_dt,   "Supervised",   haplotype = cur_hap)
  p_violin_unsup  = violin_plot(merge_unsup_dt, "Unsupervised", haplotype = cur_hap)
  p_precrec_sup   = precrec_plot(all_itrs, "Supervised",   haplotype = cur_hap, method = "sup")
  p_precrec_unsup = precrec_plot(all_itrs, "Unsupervised", haplotype = cur_hap, method = "unsup")

  ggarrange(p_violin_sup, p_violin_unsup, p_precrec_sup, p_precrec_unsup,
            ncol = 2, nrow = 2, labels = "AUTO")
  ggsave(paste0(pdf_folder, cur_hap, ".pdf"), width = 10, height = 10)
}

plot_haplotype("APOE")
plot_haplotype("ABO")
plot_haplotype("LCT")
plot_haplotype("FUT2")
plot_haplotype("DQB1_602")
