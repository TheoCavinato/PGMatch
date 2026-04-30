#!/bin/bash
#SBATCH --job-name PGMatch
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/Sensitive_haplotypes_inference/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 5G
#SBATCH --time 00:30:00
#SBATCH --cpus-per-task 10
#SBATCH --get-user-env=L
#SBATCH --export NONE

module load r-light


#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

NBR_PHENO=40
N_TRAIN=1000
ITR=$1

. .env
mkdir -p $N_PHENO_FOLDER/PGMatch_results

#------------------------------------------------------------------------------#
# Run
#------------------------------------------------------------------------------#

create_sub_df(){
	IND=$1
	. .env
	# create phenotype
	interest_line=$(zcat $PHENO_test | head -n $((IND+1)) | tail -1)
	zcat $PHENO_test | head -n1 > $IND_PHENO
	yes "$interest_line" | head  -n 100000 >> $IND_PHENO

	# validation
	awk 'NR==2{seen[$1]++} NR>2{if(seen[$1] == 0) {print "error: multiple ids in IND pheno"; exit 1}}' $IND_PHENO

}

run_pgmatch(){
	IND=$1
	. .env

	mkdir -p $N_PHENO_FOLDER/PGMatch_results_ind$IND/
	#------------------------------------------------------------------------------#
	# As we have the same individual in every rows, we cannot use the quantile 
	# normalization method. We thus need to quantile normlaize the data
	# based on the mean and standaard deviation of the training data
	#------------------------------------------------------------------------------#

	create_sub_df $IND

	#------------------------------------------------------------------------------#
	# 3. Compute LLR on testing set
	#------------------------------------------------------------------------------#

	# supervised model
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_sup_scaled --pheno $IND_PHENO --r2 $R2 --ce $CE --llr $SUP_TEST_LLR --qnorm F

	# unsupervised method
	Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_unsup_scaled --pheno $IND_PHENO --r2 $LDSC_H2 --ce $LDSC_CG --llr $UNSUP_TEST_LLR  --qnorm F

	#------------------------------------------------------------------------------#
	# 4. Convert LLR to probas using Kernel Density Estimation
	#------------------------------------------------------------------------------#

	# supervised method
	Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA

	# unsupervised method
	Rscript $PGMATCH/llr2probas.r --llr_test $UNSUP_TEST_LLR --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --round 10 --probas $UNSUP_PROBA
	cp $UNSUP_PROBA $SUP_PROBA $N_PHENO_FOLDER/PGMatch_results/
	rm -r $N_PHENO_FOLDER/PGMatch_results_ind$IND/

}


mkdir -p $N_PHENO_FOLDER/PGMatch_results/

#------------------------------------------------------------------------------#
# 1. Compute Ce, Cg and r2 on training individuals 
#------------------------------------------------------------------------------#
Rscript $PGMATCH/compute_ce_cg_r2.r --pgs $PGS_train --pheno $PHENO_train --r2 $R2 --ce $CE --cg $CG &

#------------------------------------------------------------------------------#
# 2. Compute LLR on training set 
#------------------------------------------------------------------------------#
wait

# supervised method
Rscript $PGMATCH/llr_computation.r --pgs $PGS_train --pheno $PHENO_train --r2 $R2 --ce $CE --llr $SUP_TRAIN_LLR_H1 &
Rscript $PGMATCH/llr_computation.r --pgs $PGS_train_h0 --pheno $PHENO_train --r2 $R2 --ce $CE --llr $SUP_TRAIN_LLR_H0 &
wait

# unsupervised model
Rscript Scripts/format_ldsc_r2.r --pheno_file $R2 --ori_ldsc_cg $ORI_LDSC_CG --ori_ldsc_cv $ORI_LDSC_CV --h2 $LDSC_H2 --ldsc_cg $LDSC_CG
Rscript $PGMATCH/llr_simulation.r --r2 $LDSC_H2 --ce $LDSC_CG --cg $LDSC_CG --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --n_sim $N_TRAIN

#------------------------------------------------------------------------------#
# 3. Compute LLR on testing (as a validation)
#------------------------------------------------------------------------------#

# supervised model
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_VALID  &
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_VALID_H0  &

# unsupervised method
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $UNSUP_TEST_LLR_VALID  &
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_h0 --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $UNSUP_TEST_LLR_VALID_H0 &
wait


#------------------------------------------------------------------------------#
# 4. Scale the PGS urself and check that u obtain the same results
#------------------------------------------------------------------------------#

# supervised
Rscript Scripts/scale_test_using_train.r $PGS_train $PGS_test $PGS_test_sup_scaled &
Rscript Scripts/scale_test_using_train.r $PGS_train $PGS_test_h0 $PGS_test_sup_scaled_h0 &
wait

Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_sup_scaled --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_VALID_SCALED --qnorm F &
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_sup_scaled_h0 --pheno $PHENO_test --r2 $R2 --ce $CE --llr $SUP_TEST_LLR_VALID_SCALED_H0 --qnorm F &
wait

# unsupervised
while read line; do
	PHENO_ID=$(echo $line | cut -d' ' -f1 )
	. .env
	echo $(cat $ESTIMATED_MEAN_AND_VAR) $(zcat $LDPRED_PATH | wc -l)
done < $USED_PHENO > $ESTIMATED_MEAN_AND_VAR_CAT

unsup_scale_func(){
awk 'FNR==NR{means[NR]=$2;sds[NR]=sqrt($4); n_snps[NR]=$6; next}
	{
	if(FNR>1) for(i = 2; i<=NF; i++) { $i=($i*n_snps[i-1]*2-means[i-1])/ sds[i-1] }
	print 
	}' $ESTIMATED_MEAN_AND_VAR_CAT <(zcat $1) > $2
}
unsup_scale_func $PGS_test $PGS_test_unsup_scaled &
unsup_scale_func $PGS_test_h0 $PGS_test_unsup_scaled_h0 &
wait

Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_unsup_scaled --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $UNSUP_TEST_LLR_VALID_SCALED --qnorm F &
Rscript $PGMATCH/llr_computation.r --pgs $PGS_test_unsup_scaled_h0 --pheno $PHENO_test --r2 $LDSC_H2 --ce $LDSC_CG --llr $UNSUP_TEST_LLR_VALID_SCALED_H0 --qnorm F &
wait


#------------------------------------------------------------------------------#
# Compute probabilities
#------------------------------------------------------------------------------#

# compute proba
Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_VALID --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_VALID &
Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_VALID_H0 --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_VALID_H0 &

Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_VALID_SCALED --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_VALID_SCALED &
Rscript $PGMATCH/llr2probas.r --llr_test $SUP_TEST_LLR_VALID_SCALED_H0 --llr_h0 $SUP_TRAIN_LLR_H0 --llr_h1 $SUP_TRAIN_LLR_H1 --round 10 --probas $SUP_PROBA_VALID_SCALED_H0 &

# compute proba
Rscript $PGMATCH/llr2probas.r --llr_test $UNSUP_TEST_LLR_VALID --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --round 10 --probas $UNSUP_PROBA_VALID &
Rscript $PGMATCH/llr2probas.r --llr_test $UNSUP_TEST_LLR_VALID_H0 --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --round 10 --probas $UNSUP_PROBA_VALID_H0 &

Rscript $PGMATCH/llr2probas.r --llr_test $UNSUP_TEST_LLR_VALID_SCALED --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --round 10 --probas $UNSUP_PROBA_VALID_SCALED &
Rscript $PGMATCH/llr2probas.r --llr_test $UNSUP_TEST_LLR_VALID_SCALED_H0 --llr_h0 $UNSUP_TRAIN_LLR_H0 --llr_h1 $UNSUP_TRAIN_LLR_H1 --round 10 --probas $UNSUP_PROBA_VALID_SCALED_H0 &
wait

export -f run_pgmatch
export -f create_sub_df
export ITR NBR_PHENO

seq 1 1000 | xargs -n 1 -P 10 -I {} bash -c 'run_pgmatch "$@"' _ {}
