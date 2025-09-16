#!/bin/bash
#SBATCH --job-name LDSC
#SBATCH --output /scratch/tcavinat/Phenotype_inference_attack/LDSC/logs/%x_%A-%a.out
#SBATCH --error  /scratch/tcavinat/Phenotype_inference_attack/LDSC/logs/%x_%A-%a.err
#SBATCH --partition urblauna
#SBATCH --mem 30G
#SBATCH --time 05:20:00
#SBATCH --get-user-env=L
#SBATCH --export NONE
#SBATCH --cpus-per-task=1

module load r-light

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# load variables
. .env

# output
mkdir -p $DATA/LDSC_results

#------------------------------------------------------------------------------#
# Run ldsc to obtain genetic correlations
#------------------------------------------------------------------------------#
echo "PHENO PATH N" > $PHENO_LIST
while read line; do
	PHENO=`echo $line  | awk '{print $1}'`
	. .env
	MUNGE_FILE=$DATA/Munge/$PHENO.sumstats.gz
	N=`zcat $MUNGE_FILE | head -n 2 | awk 'NR>1{print $2}'`
	echo $PHENO $MUNGE_FILE $N >> $PHENO_LIST
done < <(cat $VAR_EXPL | awk '{if($2 > 0.05) {print}}') # filter phenotypes with a too low var expl

Rscript Scripts/gen_cor.r --path_to_ld_matrices $LD \
	--input_p $PHENO_LIST \
	--out_s $GENCOR_S \
	--out_v $GENCOR_V \
	--out_i $GENCOR_I \
	--out_s_stand $GENCOR_S_stand \
	--out_v_stand $GENCOR_V_stand \
	--out_dir $DATA/LDSC_results


