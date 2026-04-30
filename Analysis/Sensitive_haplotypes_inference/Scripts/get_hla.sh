
. .env

#------------------------------------------------------------------------------#
# HLA
#------------------------------------------------------------------------------#

awk -F '\t' 'BEGIN{system("cat Scripts/hla_header.txt")}
	NR>1{if($12254!="NA") {print $1"\t"$12254}
	else{printf $1; for (i=0; i<362; i++) {printf "\tNA"}; printf "\n"}}' $ORI_PHENO_FILE |\
	sed 's/"//g' |\
	sed "s/,/\t/g" > $HLA_MAT
