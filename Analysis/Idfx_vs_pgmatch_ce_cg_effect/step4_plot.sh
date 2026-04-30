
. .env

mkdir -p $PLOT_FOLDER

concat_func(){
	zcat $1 | awk -v r2_file=$2 -v met=$3 -v itr=$4 'NR>1{print r2_file,met,itr,$2,$1}'
}

#echo "ce_cg_file method itr group proba" > $DATA_DF
#for CE_CG_FILE in $CE_CG_FILE1 $CE_CG_FILE2 $CE_CG_FILE3 $CE_CG_FILE4 $CE_CG_FILE5; do
#	for ITR in {1..100};do
#	. .env
#	echo $SUP_PROBAS
#	concat_func $SUP_PROBAS ${CE_CG_FILE} "PGMatch"  $ITR >> $DATA_DF
#	concat_func $REAL_IDFX_PROBAS ${CE_CG_FILE} "IDEFIX" $ITR >> $DATA_DF
#	done
#done 

#cp $DATA_DF $PLOT_WORK_FOLDER

Rscript Scripts/precision_recall.r --data_df $PLOT_WORK_FOLDER/plot_effect_data.tsv --out_pdf $PRECREC_PDF
