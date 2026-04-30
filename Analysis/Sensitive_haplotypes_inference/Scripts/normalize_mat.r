library(data.table)
args=commandArgs(trailingOnly=T)

# args 1 -> path
# args 2 -> means
# args 3 -> sd
dt = fread(args[1])

mean_vec <- as.numeric(strsplit(args[2], ",")[[1]])
sd_vec <- as.numeric(strsplit(args[3], ",")[[1]])

cols <- setdiff(names(dt), "IID")
dt[, (cols) := Map(function(col, c, s) (col - c) / s,
                   .SD, mean_vec, sd_vec),
   .SDcols = cols]

fwrite(dt, args[4], sep="\t")
