

# how to get the time and memory my frined?

N_TEST=1000
N_TRAIN=1000
. .env
mkdir -p $PLOT_FOLDER

#------------------------------------------------------------------------------#
# Useful functions
#------------------------------------------------------------------------------#

get_time(){
grep "Elapsed (wall clock) time" $1 |\
	awk '{split($NF,splt_arr,":");
	if(length(splt_arr) != 2){ print "error" ;exit 1}
	print splt_arr[1]*60+splt_arr[2]
	}'
}

get_mem(){
grep "Maximum resident set size (kbytes)" $1 | awk '{print $NF}'
}

#echo "method n_test n_train nbr_pheno itr mem_kbytes time_spent" > $CONCAT_TIME_MEM
#for NBR_PHENO in 10 20 30 40; do
#for ITR in {1..10}; do
#
#. .env
#new_line="$N_TEST $N_TRAIN $NBR_PHENO $ITR" 
#echo "pgmatch" $new_line $(get_mem $TIME_MY_METHOD) $(get_time $TIME_MY_METHOD)
#echo "idfx_train" $new_line $(get_mem $TIME_IDFX_TRAIN) $(get_time $TIME_IDFX_TRAIN)
#echo "idfx_test" $new_line $(get_mem $TIME_IDFX_TEST) $(get_time $TIME_IDFX_TEST)
#
#done
#done >> $CONCAT_TIME_MEM
#
## do the same for the number of N_TEST
#NBR_PHENO=10
#for N_TEST in $(seq 2000 1000 10000);do
#for ITR in {1..10}; do
#. .env
#new_line="$N_TEST $N_TRAIN $NBR_PHENO $ITR" 
#echo "pgmatch" $new_line $(get_mem $TIME_MY_METHOD) $(get_time $TIME_MY_METHOD)
#echo "idfx_train" $new_line $(get_mem $TIME_IDFX_TRAIN) $(get_time $TIME_IDFX_TRAIN)
#echo "idfx_test" $new_line $(get_mem $TIME_IDFX_TEST) $(get_time $TIME_IDFX_TEST)
#done
#done >> $CONCAT_TIME_MEM

#cp $CONCAT_TIME_MEM $PLOT_WORK_FOLDER
#Rscript Scripts/plot_result.r --concat_data $CONCAT_TIME_MEM --out_png $TIME_MEM_PNG
Rscript Scripts/plot_result.r --concat_data $PLOT_WORK_FOLDER/concat_time_mem.tsv --out_pdf $TIME_MEM_PDF
