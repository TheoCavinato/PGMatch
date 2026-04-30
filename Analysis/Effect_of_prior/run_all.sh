

N_TEST=100000
N_TRAIN=1000
NBR_PHENO=40

for ITR in {1..100}; do
jobid1=$(sbatch --parsable step1_create_datasets.sh $N_TEST $N_TRAIN $NBR_PHENO $ITR)
jobid2=$(sbatch --parsable --dependency=afterok:${jobid1} step2_pgmatch_training.sh $N_TEST $N_TRAIN $NBR_PHENO $ITR)
sbatch --parsable --dependency=afterok:${jobid2} step3_pgmatch_testing.sh $N_TEST $N_TRAIN $NBR_PHENO $ITR
done
