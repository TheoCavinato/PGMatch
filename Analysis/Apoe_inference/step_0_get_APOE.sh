
module load bcftools

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# load variables
. .env

# make necessary output directories
mkdir -p $SCRATCH/tmp/

#------------------------------------------------------------------------------#
# Create phenotype
#------------------------------------------------------------------------------#

echo "assert the indidivduals are sorted the same (should not echo anything)"
bcftools query -l $APOE_BCF1 > $SAMPLE1
bcftools query -l $APOE_BCF2 > $SAMPLE2
diff $SAMPLE1 $SAMPLE2

echo "create phenotype..."
bcftools query -f "[%GT\t]\n" $APOE_BCF1 |\
	sed "s/|/\t/g" |\
	sed "s/\t/\n/g" |\
	head -n -1 > $POS1

bcftools query -f "[%GT\t]\n" $APOE_BCF2 |\
	sed "s/|/\t/g" |\
	sed "s/\t/\n/g" |\
	head -n -1 > $POS2

paste $POS1 $POS2 |\
	sed "s/\t//g" |\
	sed "s/00/e3/g" |\
	sed "s/10/e4/g" |\
	sed "s/11/e3r/g" |\
	sed "s/01/e2/g" > $APOE_STATUS
	
awk 'NR % 2 == 1 { printf "%s", $0 } NR % 2 == 0 { print }' $APOE_STATUS > $APOE_STATUS_PER_IND.tmp
paste $SAMPLE1 $APOE_STATUS_PER_IND.tmp > $APOE_STATUS_PER_IND

echo "assert that the number of individuals is ok (following 3 numbers should be the same)"
wc -l $APOE_STATUS_PER_IND $SAMPLE1 $SAMPLE2

#------------------------------------------------------------------------------#
# Validation: check frequency of each haplotype
#------------------------------------------------------------------------------#

echo "------------------------------------------------------------------------------"
echo "assert frequency of each haplotype"
TOTAL=$(wc -l < $APOE_STATUS)
sort $APOE_STATUS |\
	uniq -c |\
	awk -v total=$TOTAL 'BEGIN{print "haplotype\tfreq"}{print $2"\t"$1/total}'
echo \
"based on this paper: https://pmc.ncbi.nlm.nih.gov/articles/PMC12081911/
you should get something like
e2: 7.1
e3: 74.2
e4: 18.7"

#------------------------------------------------------------------------------#
# Validation: compare to PGS of Alzheimer disease??? (if you really have time)
#------------------------------------------------------------------------------#

echo "------------------------------------------------------------------------------"
echo "assert frequency of each combination of haplotype"
echo \
"based on this paper: https://www.sciencedirect.com/science/article/pii/S2352396420303303
you should get something like
e2e2 0.6
e2e3 12.3
e2e4 2.6
e3e3 58.3
e3e4 23.9
e4e4 2.4
"

TOTAL_IND=$(wc -l < $APOE_STATUS_PER_IND)
echo $TOTAL $TOTAL_IND
cut -f2 $APOE_STATUS_PER_IND |\
	sed "s/e3e2/e2e3/" |\
	sed "s/e4e2/e2e4/" |\
	sed "s/e4e3/e3e4/" |\
	sort |\
	uniq -c |\
	awk -v total=$TOTAL_IND 'BEGIN{print "haplotype\tfreq"}{print $2"\t"$1/total}'
	
