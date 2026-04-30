

DATA_FOLDER=/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Plot_data/Sensitive_haplotypes_inference/Haplotypes

echo "precision ABO at lowest threshold: 0.4420000"
echo "freq in our dataset compute:"
awk 'NR>1{sum+=($NF=="OO")}END{print sum/NR}' $DATA_FOLDER/abo_reformat.snp
echo  "precision FUT2 at lowest threshold: 0.7620000"
echo "freq in our dataset compute:"
awk 'NR>1{sum+=($NF>=1)}END{print sum/NR}' $DATA_FOLDER/fut2.snp.raw
echo  "precision LCT at lowest threshold: 0.8710000"
echo "freq in our dataset compute:"
awk 'NR>1{sum+=($NF>=1)}END{print sum/NR}' $DATA_FOLDER/lct.snp.raw
echo  "precision DBQ1 at lowest threshold: 0.2450000"
echo "freq in our dataset compute:"
awk 'NR>1 && $301!="NA" {sum+=($301 >= 1); n_line+=1}END{print sum/n_line}' $DATA_FOLDER/hla_mat.tsv 
