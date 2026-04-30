
. .env

mkdir -p $PLOT_FOLDER

concat_func(){
	zcat $1 | awk -v r2_file=$2 -v met=$3 -v itr=$4 'NR>1{print r2_file,met,itr,$2,$1}'
}

#echo "r2_file method itr group proba" > $DATA_DF
#for CURRENT_R2_FILE in $R2_FILE_1 $R2_FILE_4 $R2_FILE_5 $R2_FILE_7; do
#	R2_FILE=$CURRENT_R2_FILE
#	for ITR in {1..100};do
#	. .env
#	concat_func $SUP_PROBAS ${R2_FILE%.*} "PGMatch"  $ITR >> $DATA_DF
#	concat_func $REAL_IDFX_PROBAS ${R2_FILE%.*} "IDEFIX" $ITR >> $DATA_DF
#	done
#done 
#
#cp $DATA_DF $PLOT_WORK_FOLDER
Rscript Scripts/precision_recall.r --data_df $PLOT_WORK_FOLDER/plot_effect_data.tsv --out_pdf $PRECREC_PDF

