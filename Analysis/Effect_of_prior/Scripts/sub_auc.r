library(data.table)
library(PRROC)

args=commandArgs(trailingOnly=T)

concat_dt = fread(args[1])
names(concat_dt) = c("group", "method", "itr", "proba")

# function that will resample the individuals n times depending on the numebr of match
precrec_subset = function(concat_dt, cur_method){ 
	print("you reached the function")
	recall_grid <- seq(0, 1, length.out = 100)

	df_h0 = subset(concat_dt, method==cur_method & group == "H0")
	df_h1 = subset(concat_dt, method==cur_method & group == "H1")

	#print(unlist(lapply(c(1:100), function(i) {
	#pr = pr.curve(
	#    scores.class1 = subset(df_h0, itr==i)$proba,
	#    scores.class0 = subset(df_h1, itr==i)$proba
	#    curve = TRUE)$auc.integral})))
	return(data.table(auc = unlist(lapply(c(1:100), function(i) {
	  pr.curve(
	    scores.class1 = subset(df_h0, itr==i)$proba,
	    scores.class0 = subset(df_h1, itr==i)$proba,
	    curve = TRUE)$auc.integral
	})),
	method = cur_method,
	itr=c(1:100)))
#	print(data.table(auc=unlist(),
#	method = cur_method))
	

}

df_pr = rbind(precrec_subset(concat_dt, "supervised"), precrec_subset(concat_dt, "unsupervised"))

fwrite(df_pr, args[2], sep="\t")
