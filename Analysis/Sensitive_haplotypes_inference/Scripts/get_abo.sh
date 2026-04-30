module load plink2

. .env
mkdir -p $HAPLO_FOLDER


#------------------------------------------------------------------------------#
# ABO
#------------------------------------------------------------------------------#

# See https://biobank.ndph.ox.ac.uk/ukb/field.cgi?id=23165
# to get why we use those snps
CHR=9

. .env
plink2 --pfile $GENO_PLINK --extract <(echo -e "rs505922\nrs8176719\nrs8176746") --recode A --out $ABO_GENO

awk 'NR>1{

	$10=""
	# get O
	if($8 != "NA" && $8 != 2) for(i=2;i>$8;i--) $10=$10"O" # deletion on rs8176719_TC
	else if($8 == "NA" && $9!=2) for(i=2;i>$8;i--) $10=$10"O" # if no info on rs8176719_TC, use rs505922 of T

	# get B
	if ($7!="NA" && $7 > 0) for(i=0;i<$7 && length($10) < 2;i++) $10=$10"B"

	# get A
	for(i = length($10); i<2; i++) $10=$10"A"

	# validations
	print
	if(length($10) != 2) exit 1

}' $ABO_GENO.raw > $REFORMAT_ABO_GENO

# validation
echo "Here are the numebrs reported by UKB:
AA 36'308
BA 17'595
BB 2'786
OA 175'044
OB 44'007
OO 211'272
"

echo "Here are the numbers you generated:"
awk '{print $NF}' $REFORMAT_ABO_GENO | sort | uniq -c

