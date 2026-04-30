

. .env

mkdir -p $R2_FOLDER

awk 'BEGIN{print "r2"; for(i=0; i<10;i++) print "0.5"}' > $R2_FOLDER/$R2_FILE_1
awk 'BEGIN{print "r2"; for(i=0; i<10;i++) if(i < 5) print "0.5"; else print "0.005"}' > $R2_FOLDER/$R2_FILE_2
awk 'BEGIN{print "r2"; for(i=0; i<10;i++) print "0.005"}' > $R2_FOLDER/$R2_FILE_3

awk 'BEGIN{print "r2"; for(i=0; i<10;i++) if(i < 5) print "0.5"; else print "0.05"}' > $R2_FOLDER/$R2_FILE_4
awk 'BEGIN{print "r2"; for(i=0; i<10;i++) print "0.05"}' > $R2_FOLDER/$R2_FILE_5

awk 'BEGIN{print "r2"; for(i=0; i<10;i++) print rand()}' > $R2_FOLDER/$R2_FILE_6

awk 'BEGIN{print "r2"; for(i=0; i<10;i++) if(i < 9) print "0.05"; else print "0.5"}' > $R2_FOLDER/$R2_FILE_7

VAR_EXPL_NO_CORR=/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Compute_variance_explained/variance_explained.many_inds.no_corr.tsv
awk 'NR==1{print "r2"} NR>1 && NR<12 {print $2}' $VAR_EXPL_NO_CORR > $R2_FOLDER/$R2_FILE_8

