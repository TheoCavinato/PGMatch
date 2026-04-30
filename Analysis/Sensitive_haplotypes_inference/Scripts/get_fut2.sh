
module load plink2 
#------------------------------------------------------------------------------#
# Get FUT2
#------------------------------------------------------------------------------#

CHR=19

. .env

plink2 --pfile $GENO_PLINK --snp rs601338 --recode A --out $FUT2_GENO

# validation

# pmc.ncbi.nlm.nih.gov/articles/PMC6171556/
## About 20% of Caucasians are homozygous for the nonsense mutation W143X (rs601338G>A)
awk 'NR>1{sum+=($NF==2)}END{print sum/(NR)}'  $FUT2_GENO.raw
