
module load plink2 
#------------------------------------------------------------------------------#
# Get FUT2
#------------------------------------------------------------------------------#

CHR=2

. .env

plink2 --pfile $GENO_PLINK --snp rs4988235 --recode A --out $LCT_GENO

# validation
# https://pmc.ncbi.nlm.nih.gov/articles/PMC7614013/?utm_source=chatgpt.com
# Minor allele frequency and Hardy Weinberg Equilibrium p-value for the rs4988235 were 0.25 and 0.600
# means that the G and A alleles are the lactase non-persistent and lactase-persistent alleles,
grep -v NA $LCT_GENO.raw | awk 'NR>1{sum+=$NF}END{print sum/(NR*2)}'
