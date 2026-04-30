
# Make precision recall curve based on the 100 simulations


. .env
mkdir -p $PLOT_FOLDER

#------------------------------------------------------------------------------#
# Concat the data
#------------------------------------------------------------------------------#

concat_proba_func(){
	zcat $1 | awk -v met=$2 -v group=$3 -v n_pheno=$4 -v itr=$5 'NR>1{print $2,met,group,n_pheno,itr}'
}

#for NBR_PHENO in 10 20 {21..29} 30 {31..40}; do
#for NBR_PHENO in {30..39}; do
for NBR_PHENO in {30..38}; do
	for ITR in {1..100};do
	. .env
	concat_proba_func $SUP_PROBA_H0 "supervised" "H0" $NBR_PHENO $ITR
	concat_proba_func $SUP_PROBA_H1 "supervised" "H1" $NBR_PHENO $ITR
	concat_proba_func $UNSUP_PROBA_H0 "unsupervised" "H0" $NBR_PHENO $ITR
	concat_proba_func $UNSUP_PROBA_H1 "unsupervised" "H1" $NBR_PHENO $ITR
	concat_proba_func $REVIEWER2_UNSUP_PROBA_H0 "reviewer2_unsupervised" "H0" $NBR_PHENO $ITR
	concat_proba_func $REVIEWER2_UNSUP_PROBA_H1 "reviewer2_unsupervised" "H1" $NBR_PHENO $ITR
	done
done > $CONCAT_DATA

cp $CONCAT_DATA $PLOT_WORK_FOLDER

#for NBR_PHENO in 5 10 20 30 40; do
#	for ITR in {1..100}; do
#	echo "copying itr $ITR pheno $NBR_PHENO"
#	. .env
#	mkdir -p $PLOT_ITR_FOLDER
#	cp $ITR_FOLDER/PGMatch_results/* $PLOT_ITR_FOLDER
#	done
#done

#------------------------------------------------------------------------------#
# Make plots
#------------------------------------------------------------------------------#

# plot LLR
ITR=1
. .env

Rscript Scripts/auc_comparison.30_to_40.r --concat_data $PLOT_WORK_FOLDER/concat_all_phenos.tsv --out_pdf $AUC_30_40_PDF --out_auc_table $AUC_30_40_TABLE

