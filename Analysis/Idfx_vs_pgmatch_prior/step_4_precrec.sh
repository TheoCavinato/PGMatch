

module load r-light

# Prepare your method as dataset
NBR_PHENO=$1
N_TEST=$2
N_TRAIN=$3

. .env
concat_func(){
zcat $1 | awk -v group=$2 -v met=$3 -v itr=$4 'NR>1{ print itr,met,group,$2}'
}

#mkdir -p $PRECREC_FOLDER
#:> $DATA_DF
#for ITR in {1..100}; do
#	. .env
#	concat_func $SUP_PROBAS_H0 "H0" "PGMatch" $ITR >> $DATA_DF
#	concat_func $SUP_PROBAS "H1" "PGMatch" $ITR >> $DATA_DF
#	concat_func $REAL_IDFX_PROBAS_H0 "H0" "IDEFIX" $ITR >> $DATA_DF
#	concat_func $REAL_IDFX_PROBAS_H1 "H1" "IDEFIX" $ITR >> $DATA_DF
#done

#cp $DATA_DF $PLOT_WORK_FOLDER
#Rscript Scripts/precision_recall.r --concat_data $DATA_DF --out_png $PRECREC_PNG
Rscript Scripts/precision_recall.r --concat_data $PLOT_WORK_FOLDER/concat.tsv --out_pdf $PRECREC_PDF

#Rscript Scripts/precision_recall.r --my_method_h0 $SUP_PROBAS_H0 \
#	--my_method_h1 $SUP_PROBAS \
#	--idfx_h0 $REAL_IDFX_PROBAS_H0 \
#	--idfx_h1 $REAL_IDFX_PROBAS_H1 \
#	--out_png $PRECREC_PNG
#
