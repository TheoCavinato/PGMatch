
NBR_PHENO=10

. .env

const_cor_mat(){
awk -v NBR_PHENO=$1 -v CORR_VAL=$2 'BEGIN{
	diag_id = 1
	for(i = 1; i<=NBR_PHENO*NBR_PHENO; i++) {
	// decide value
	if(i == diag_id){ printf "1.0"
	diag_id+=(NBR_PHENO+1)}
	else{printf CORR_VAL}
	// decide separator
	if(i%NBR_PHENO==0){ printf "\n"}
	else {printf " "}}}'
}

half_const_cor_mat(){
awk -v NBR_PHENO=$1 -v CORR_VAL=$2 'BEGIN{
	diag_id = 1
	for(i = 1; i<=NBR_PHENO*NBR_PHENO; i++) {
	// decide value
	if(i == diag_id){ printf "1.0"
	diag_id+=(NBR_PHENO+1)}
	else if( (i%NBR_PHENO) <= NBR_PHENO/2 && (i/NBR_PHENO) <= NBR_PHENO/2 && (i%NBR_PHENO)){ printf CORR_VAL}
	else{printf "0.0"}
	// decide separator
	if(i%NBR_PHENO==0){ printf "\n"}
	else {printf " "}}}'
}

mkdir -p $CE_CG_FOLDER
const_cor_mat $NBR_PHENO 0.0 > $CE_CG_FOLDER/$CE_CG_FILE1.ce; const_cor_mat $NBR_PHENO 0.5 > $CE_CG_FOLDER/$CE_CG_FILE1.cg
const_cor_mat $NBR_PHENO 0.5 > $CE_CG_FOLDER/$CE_CG_FILE2.ce; const_cor_mat $NBR_PHENO 0.0 > $CE_CG_FOLDER/$CE_CG_FILE2.cg
const_cor_mat $NBR_PHENO 0.5 > $CE_CG_FOLDER/$CE_CG_FILE3.ce; const_cor_mat $NBR_PHENO 0.5 > $CE_CG_FOLDER/$CE_CG_FILE3.cg
const_cor_mat $NBR_PHENO 0.0 > $CE_CG_FOLDER/$CE_CG_FILE4.ce; const_cor_mat $NBR_PHENO 0.0 > $CE_CG_FOLDER/$CE_CG_FILE4.cg
half_const_cor_mat $NBR_PHENO 0.5 > $CE_CG_FOLDER/$CE_CG_FILE5.ce; half_const_cor_mat $NBR_PHENO 0.5 > $CE_CG_FOLDER/$CE_CG_FILE5.cg
