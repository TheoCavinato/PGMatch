library(data.table)

# Convert idfx dataset to my version of dataset

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

args = commandArgs(trailingOnly=T)
# input
idfx_p = args[1]
me_h1_p = args[2]
me_h0_p =  args[3]

# output
out_h1 = args[4]
out_h0 = args[5]

# debugging
#idfx_p =  "/scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix/Analysis.N_TEST_10000.N_TRAIN_1000/Training/train_model_out_2_phenos.n_1000/aggregatedLogLikelihoodRatiosMatrix.rds"
#me_h1_p = "/scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix/Analysis.N_TEST_10000.N_TRAIN_1000/Datasets/pgs.train.tsv.gz"
#me_h0_p = "/scratch/tcavinat/Phenotype_inference_attack/Assurancetourix_vs_idefix/Analysis.N_TEST_10000.N_TRAIN_1000/Datasets/pgs.train.h0.tsv.gz"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

# import ids of mismatch in my data
me_h1_iids = as.character(fread(me_h1_p, hea=T)$IID)
me_h0_iids = as.character(fread(me_h0_p, hea=T)$IID)

# import the idfx
idfx_llr = readRDS(idfx_p)

# filter rows and cols
llr_h1 = idfx_llr[cbind(me_h1_iids, me_h1_iids)]
llr_h0 = idfx_llr[cbind(me_h1_iids, me_h0_iids)]

#------------------------------------------------------------------------------#
# Write output as normal output of our method
#------------------------------------------------------------------------------#
llr_h1_df = data.table(IID=me_h1_iids, llr=llr_h1)
llr_h0_df = data.table(IID=me_h1_iids, llr=llr_h0)
gz_out = gzfile(out_h1, "w")
write.table(llr_h1_df, gz_out, quote=F, row.names=F)
close(gz_out)
gz_out = gzfile(out_h0, "w")
write.table(llr_h0_df, gz_out, quote=F, row.names=F)
close(gz_out)

