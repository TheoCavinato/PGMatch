
module load r-light

N_TEST=$1
N_TRAIN=$2
NBR_PHENO=$3
N_MATCH=$4
N_MISMATCH=$5

. .env
mkdir -p $PLOT_FOLDER

#------------------------------------------------------------------------------#
# Concat data
#------------------------------------------------------------------------------#

awk_func(){
	awk -v method=$1 -v group=$2 -v itr=$3 '{ printf "%s %s %s %.10f\n",group,method,itr,$2}'
}

#:>$CONCAT_DATA
#for ITR in {1..100}; do
#	. .env
#	zcat $SUP_PROBA_H1 | tail -n +2 | shuf | head -n $N_MATCH | awk_func "supervised" "H1" $ITR >> $CONCAT_DATA
#	zcat $UNSUP_PROBA_H1 | tail -n +2 | shuf | head -n $N_MATCH | awk_func "unsupervised" "H1" $ITR >> $CONCAT_DATA
#
#	TO_WRITE=$N_MISMATCH
#	WHEEL=1
#	echo $ITR $TO_WRITE
#	while [ $TO_WRITE -gt 0 ]; do
#		. .env
#		CURR_WRITE=$(($TO_WRITE > 100000 ? 100000 : $TO_WRITE))
#		zcat $SUP_PROBA_H0 | tail -n +2 | shuf | head -n $((CURR_WRITE)) | awk_func "supervised" "H0" $ITR >> $CONCAT_DATA
#		zcat $UNSUP_PROBA_H0 | tail -n +2 | shuf | head -n $((CURR_WRITE)) | awk_func "unsupervised" "H0" $ITR >> $CONCAT_DATA
#		TO_WRITE=$((TO_WRITE - 100000))
#		WHEEL=$((WHEEL+1))
#	done
#
#done

#cp $PLOT_FOLDER/concat.*.*.tsv $PLOT_WORK_FOLDER
#cp $PLOT_FOLDER/auc.*.*.tsv $PLOT_WORK_FOLDER
#Rscript Scripts/sub_prec_rec.r $CONCAT_DATA $PRECREC_SUB_DATA
#Rscript Scripts/sub_auc.r $CONCAT_DATA $AUC_SUB_DATA
#cp $PLOT_FOLDER/precrec.*.*.tsv $PLOT_WORK_FOLDER
#Rscript Scripts/plot_precrec.r $PRECREC_PDF

Rscript Scripts/make_auc_table.r $AVG_AUC_TSV
echo "Method & Match:Mismatch ratio & Avg. AUC \\\\" > $AUC_TABLE_FORMAT_LATEX
echo "\hline" >> $AUC_TABLE_FORMAT_LATEX
awk -F '\t' 'BEGIN{OFS=" & "}NR>1{print $1,$2,$3 " \\\\"}' $AVG_AUC_TSV >> $AUC_TABLE_FORMAT_LATEX

