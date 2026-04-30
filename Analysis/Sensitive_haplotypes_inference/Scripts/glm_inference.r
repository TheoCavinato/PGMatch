library(data.table)
library(ggpubr)
library(ggplot2)
library(PRROC)
library(caret)

# Goal: proove that we do not need the re-identificatio nto actualy make the inference

# input
pheno_test_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Plot_data/Sensitive_haplotypes_inference/pheno.test.tsv.gz"
hap_p = "/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Apoe_inference/All_haplotypes/all_haplotypes.merged.tsv.gz"

# output
out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Plots/glm.pdf"

#------------------------------------------------------------------------------#
# 1. Import data
#------------------------------------------------------------------------------#

# import phenotypes
pheno_test_dt = fread(pheno_test_p)
pheno_cols = names(pheno_test_dt)[2:41]

# import haplotypes
hap_dt = fread(hap_p)[, c("IID", "APOE","ABO","FUT2","LCT","DQB1_602")]
hap_dt[, APOE := as.integer(grepl("e4", hap_dt$APOE))]
hap_dt[, ABO := as.integer("OO" == ABO)]
hap_dt[, FUT2 := as.integer(FUT2 >= 1)]
hap_dt[, LCT := as.integer(LCT >= 1)]

hap_dt$APOE <- factor(hap_dt$APOE, levels = c(0, 1))
hap_dt$ABO <- factor(hap_dt$ABO, levels = c(0, 1))
hap_dt$FUT2 <- factor(hap_dt$FUT2, levels = c(0, 1))
hap_dt$LCT <- factor(hap_dt$LCT, levels = c(0, 1))
hap_dt[, DQB1_602 := factor(as.integer(DQB1_602 >= 1), levels=c(0,1))]

# merge pheno and haplotypes
merge_dt = merge(pheno_test_dt, hap_dt, by="IID")

#------------------------------------------------------------------------------#
# 2. Build formula: HAP ~ PHENO_1 + PHENO_2 + ... 
#------------------------------------------------------------------------------#

plot_hap = function(hap){
	message(hap)
	B <- 100   # number of bootstrap samples
	recall_grid <- seq(0, 1, length.out = 100)

	precision_mat <- matrix(NA, nrow = B, ncol = length(recall_grid))

	for (b in 1:B) {

		# bootstrap sample (with replacement)
		idx <- sample(1:nrow(sub_merge_dt), 1e4, replace = TRUE)
		test <- sub_merge_dt[idx[1:9e3], ]
		train <- sub_merge_dt[idx[9001:1e4], ]


		formula_str <- paste(hap,"~", paste(pheno_cols, collapse = " + "))
		if(b%%10==0) {cat("Boostrap", b, fill=T)}
		#cat(sprintf("Fitting model: %s\n", formula_str))
		#cat(sprintf("Train size: %s\n", nrow(train)))
		#cat(sprintf("Test size: %s\n", nrow(test)))

		model <- glm(as.formula(formula_str),
		   data   = train,
		   family = binomial(link = "logit"))

		probs <- predict(model, newdata = test, type = "response")

		pr <- pr.curve(
		scores.class0 = probs[test[[hap]]== 1],
		scores.class1 = probs[test[[hap]]== 0],
		curve = TRUE
		)

		recall <- pr$curve[,1]
		precision <- pr$curve[,2]

		# interpolate onto common grid
		precision_interp <- approx(recall, precision, xout = recall_grid, rule = 2)$y

		precision_mat[b, ] <- precision_interp
	}

	mean_precision <- colMeans(precision_mat, na.rm = TRUE)

	lower <- apply(precision_mat, 2, quantile, probs = 0.025, na.rm = TRUE)
	upper <- apply(precision_mat, 2, quantile, probs = 0.975, na.rm = TRUE)

	pr_df <- data.frame(
	  recall = recall_grid,
	  mean = mean_precision,
	  lower = lower,
	  upper = upper
	)

	p = ggplot(pr_df, aes(x = recall, y = mean)) +
	  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, fill="steelblue") +
	  geom_line(size = 1, color="darkblue") +
	  labs(
	    title = hap,
	    x = "Recall",
	    y = "Precision"
	  ) +
	  theme_minimal() +
	  theme(plot.title = element_text(hjust=0.5))
	  return(p)

}

sub_merge_dt = merge_dt[sample(1:nrow(merge_dt), 1e4, replace=F),]
stopifnot(length(unique(sub_merge_dt$IID)) == 1e4)

plot_list = c()
for(hap in c("APOE", "ABO", "FUT2", "LCT", "DQB1_602")){
	plot_list = c(plot_list, plot_hap(hap))
}

p = ggarrange(plotlist = plot_list, ncol=2, nrow=3, labels="AUTO")
ggsave(out_pdf, width=10, height=15)
