
# Make precision recall curve based on the 100 simulations


. .env
mkdir -p $PLOT_FOLDER

#------------------------------------------------------------------------------#
# Concat the data
#------------------------------------------------------------------------------#

concat_proba_func(){
	zcat $1 | awk -v met=$2 -v group=$3 -v n_pheno=$4 -v itr=$5 'NR>1{print $2,met,group,n_pheno,itr}'
}

for NBR_PHENO in 10 20 30 {31..40}; do
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
#Rscript Scripts/llr_distribution.r --llr_folder $PLOT_ITR_FOLDER --out_all_pdf $LLR_ALL_PDF --out_40_pdf $LLR_40_PDF

# plot precision recall
#Rscript Scripts/precision_recall.r --concat_data $PLOT_WORK_FOLDER/concat_all_phenos.tsv --out_pdf $PRECREC_PDF

# plot comparison mismatch vs match
#Rscript Scripts/auc_comparison.r --concat_data $PLOT_WORK_FOLDER/concat_all_phenos.tsv --out_pdf $AUC_PDF --out_auc_table $AUC_TABLE

# reformat data table for the latex
#echo "Number of traits & Inference type & AUC supervised & AUC unsupervised \\\\" > $AUC_TABLE_FORMAT_LATEX
#echo "\hline" >> $AUC_TABLE_FORMAT_LATEX
#awk -F '\t' 'BEGIN{OFS=" & "}NR>1{$1=$1;print $0 " \\\\"}' $AUC_TABLE >> $AUC_TABLE_FORMAT_LATEX
#
## plot reviewer's 2 comment
#Rscript Scripts/precision_recall_reviewer2.r --concat_data  $PLOT_WORK_FOLDER/concat_all_phenos.tsv --out_png $REVIEWER2_PDF
#


# understand problem from 30 to 40
Rscript Scripts/auc_comparison.30_to_40.r --concat_data $PLOT_WORK_FOLDER/concat_all_phenos.tsv --out_pdf $AUC_30_40_PDF --out_auc_table $AUC_30_40_TABLE
