library(data.table)

args=commandArgs(trailingOnly=T)

pgs_train = fread(args[1])
pgs_test = fread(args[2])

train_means = apply(pgs_train[, -"IID"], 2, mean)
train_sds = apply(pgs_train[, -"IID"], 2, sd)

pgs_test_scaled <- sweep(pgs_test[, -"IID"], 2, train_means, "-")
pgs_test_scaled <- cbind(data.table(IID=pgs_test$IID), sweep(pgs_test_scaled, 2, train_sds, "/"))

#apply(pgs_test_scaled, 2, mean)
#apply(pgs_test_scaled, 2, var)

fwrite(pgs_test_scaled, args[3], sep="\t")
