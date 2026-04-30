
# Check if an individual is in a biobank by computing its values against the entire biobank
# (this could be done with the data we generate for this experiment ,so i a mdoing it here,
# theese are the results that should be present in a supplementary section)
NBR_PHENO=40
. .env
#cp $SUP_PROBA_VALID_SCALED $UNSUP_PROBA_VALID_SCALED $SUP_PROBA_VALID_SCALED_H0 $UNSUP_PROBA_VALID_SCALED_H0 $PLOT_WORK_FOLDER
#cp -r /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/Nbr_pheno_40/PGMatch_results/ $PLOT_WORK_FOLDER

Rscript Scripts/check_if_in_biobank.r $SUP_PROBA_VALID_SCALED $UNSUP_PROBA_VALID_SCALED $SUP_PROBA_VALID_SCALED_H0 $UNSUP_PROBA_VALID_SCALED_H0 $CHECK_IN_PDF
