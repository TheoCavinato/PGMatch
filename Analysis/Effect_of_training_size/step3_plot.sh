
# Make precision recall curve based on the 100 simulations


. .env
mkdir -p $PLOT_FOLDER

#------------------------------------------------------------------------------#
# Concat the data
#------------------------------------------------------------------------------#

concat_proba_func(){
	zcat $1 | awk -v met=$2 -v group=$3 -v n_pheno=$4 -v n_train=$5 -v itr=$6 'NR>1{print $2,met,group,n_train,n_pheno,itr}'
}

##for NBR_PHENO in 10 20 30 40; do
#for N_TRAIN in 100 200 300 400 500 1000 5000; do
#	for NBR_PHENO in 10 20 30 40; do
#	for ITR in {1..100};do
#	. .env
#	concat_proba_func $SUP_PROBA_H0 "supervised" "H0" $NBR_PHENO $N_TRAIN $ITR
#	concat_proba_func $SUP_PROBA_H1 "supervised" "H1" $NBR_PHENO $N_TRAIN $ITR
#	concat_proba_func $UNSUP_PROBA_H0 "unsupervised" "H0" $NBR_PHENO $N_TRAIN $ITR
#	concat_proba_func $UNSUP_PROBA_H1 "unsupervised" "H1" $NBR_PHENO $N_TRAIN $ITR
#	done
#	done
#done > $CONCAT_DATA

#cp $CONCAT_DATA $PLOT_WORK_FOLDER

#Rscript Scripts/auc_plot.r --concat_data $CONCAT_DATA --out_png $AUC_PNG
Rscript Scripts/auc_plot.r --concat_data $PLOT_WORK_FOLDER/concat_all_phenos.tsv --out_pdf $AUC_PDF --out_tsv $AUC_TSV


