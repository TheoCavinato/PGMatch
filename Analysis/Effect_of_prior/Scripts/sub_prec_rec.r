library(data.table)
library(PRROC)

args=commandArgs(trailingOnly=T)

concat_dt = fread(args[1])
names(concat_dt) = c("group", "method", "itr", "proba")
print(concat_dt)

# function that will resample the individuals n times depending on the numebr of match
precrec_subset = function(concat_dt, cur_method){ 
	print("you reached the function")
	recall_grid <- seq(0, 1, length.out = 100)

	df_h0 = subset(concat_dt, method==cur_method & group == "H0")
	df_h1 = subset(concat_dt, method==cur_method & group == "H1")

	pr_matrix <- do.call(cbind, lapply(c(1:100), function(i) {
	message("itr ", i)
	sub_df_h0 = subset(df_h0, itr==i)
	sub_df_h1 = subset(df_h1, itr==i)
	pr = pr.curve(
	    scores.class1 = sub_df_h0$proba,
	    scores.class0 = sub_df_h1$proba,
	    curve = TRUE)
	approx(pr$curve[,1], pr$curve[,2], xout = recall_grid)$y}))

        df_pr = data.table(Recall=recall_grid,
                Precision=rowMeans(pr_matrix))
	df_pr$method = cur_method

	return(df_pr)
}

df_pr = rbind(precrec_subset(concat_dt, "supervised"), precrec_subset(concat_dt, "unsupervised"))

# write result
fwrite(df_pr, args[2], sep="\t")
