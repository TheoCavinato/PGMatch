
NBR_PHENO=$1
N_TEST=1000
N_TRAIN=1000

jobid1=$(sbatch --parsable step1_create_datasets.sh $N_TEST $N_TRAIN $NBR_PHENO)
jobid2=$(sbatch --parsable --dependency=afterok:${jobid1} step2_pgmatch.sh  $N_TEST $N_TRAIN $NBR_PHENO)

