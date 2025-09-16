
# input
VAR_EXPL=/data/FAC/FBM/DBC/zkutalik/default_sensitive/tcavinat/Phenotype_inference_attack/Compute_variance_explained/variance_explained.tsv
while read PHENO; do
	job1=$(sbatch --parsable step_0_log10p.sh $PHENO)
	job2=$(sbatch --parsable --dependency=afterok:$job1 step_1_munge.sh $PHENO)
done < <(awk '{print $1}' $VAR_EXPL)


