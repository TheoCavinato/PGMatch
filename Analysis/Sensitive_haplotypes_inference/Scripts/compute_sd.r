library(data.table)
args=commandArgs(trailingOnly=T)

df = fread(args[1])

cat(as.vector(apply(df[, -"IID"], 2 ,sd)), sep=",")
