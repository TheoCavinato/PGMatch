# Compute precision recall in a realistic scenario

In a realistic scenario, the precision and recall would be much smaller as the number of matches and mistmaches one would randomly sample would be very low

A realistic case (but still much better than what one could do with UKB) would be the one where the attacker knows that the individual is part of the UKB
Thus, by randomly comparing people, he would compare on average 99e3 mismatches for 1 match. 

Thus, if I want to have 1'000 match, I need to generate 99e3 * 1e3 mismatches.
Easiest way to repeat the process from *../Precision_recall_per_phenotype* but many times.


