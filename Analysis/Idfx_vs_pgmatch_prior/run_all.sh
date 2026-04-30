
for ITR in {1..100}; do
	sbatch run_all_sbatch.sh 40 10000 1000 $ITR	
done
