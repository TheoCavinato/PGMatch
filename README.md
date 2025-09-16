# Re-identification by polygenic predictions

Code supporting the paper entitled "Assessing the real threat of re-identification by polygenic predictions". \
In the main directory are the scripts an attacker could use to re-identify a genome. \
In the **Analysis/** directory are the scripts we used to perform the analysis reported in the paper.

## Quickstart
Here is a step-by-step explanation of how our method works based on an example dataset.
To try it, please first install the following **dependencies** in R:
``` install.packages("argparse", "corpcor", "data.table", "MASS", "moments", "mvtnorm", "PearsonDS") ```

### Example dataset
Our paper aims at assessing if re-identification by phenotypic prediction is possible in realistic scenarios.
In this short example, we will imagine a malicious individual had a access to **50** phenotypes of an individual *I* and stored them in **Example_data/individual_phenotypes.tsv**. 
This malicious individual also got access to the genotypes of a genome *G*, and would like to know if *G* belongs to *I*.
He computed the polygenic scores (PGS) for each phenotype of *I* on *G* and stored them in **Example_data/genome_pgs.tsv**

First, the malicious individual needs to learn how different the pgs of a genome and the phenotype of an individual are.
Fortunately, the individual got access to a biobank containing both genomes with their actual phenotypes.
He computed the polygenic scores for this phenotypes on each of the genome, and stored the result in **Example_data/biobank_pgs.tsv**.
The corresponding actual phenotypes for each of these genomes are stored in **Example_data/biobank_phenotypes.tsv**.

To generate this data, just use the script we made:
```bash
Rscript Example_data/generate_example_data.r
```

### 1. Computing necessary statistis
Thanks to the biobank, the attacker first computes the environmental (Ce) and genetic correlation (Cg) between each phenotype and their variance explained by genetics (r2) based on a given dataset of phenotypes and polygenic scores.
```bash
mkdir -p Example_output/
Rscript compute_ce_cg_r2.r --pgs Example_data/biobank_pgs.tsv \
    --pheno Example_data/biobank_phenotypes.tsv \
    --r2 Example_output/r2.tsv.gz \
    --ce Example_output/ce.tsv.gz \
    --cg Example_output/cg.tsv
```

### 2. Model trainnig
Once the attacker learned important parameters, he can learn the distrbution of the LLR in matches and mismatches
Here is to learn the distribution in matches:
```bash
Rscript llr_computation.r --pgs Example_data/biobank_pgs.tsv \
    --pheno Example_data/biobank_phenotypes.tsv \
    --r2 Example_output/r2.tsv.gz \
    --ce Example_output/ce.tsv.gz \
    --llr Example_output/llr.h1.tsv.gz
```
Here for mismatches:
```bash
head -n 1 Example_data/biobank_pgs.tsv > Example_data/biobank_pgs.shuf.tsv
tail -n +2 Example_data/biobank_pgs.tsv | shuf >> Example_data/biobank_pgs.shuf.tsv
Rscript llr_computation.r --pgs Example_data/biobank_pgs.shuf.tsv \
    --pheno Example_data/biobank_phenotypes.tsv \
    --r2 Example_output/r2.tsv.gz \
    --ce Example_output/ce.tsv.gz \
    --llr Example_output/llr.h0.tsv.gz

```
Then, he can estimate these distributions:
```bash
Rscript moments_supervised.r --llr_h0 Example_output/llr.h0.tsv.gz \
    --llr_h1 Example_output/llr.h1.tsv.gz \
    --moments Example_output/moments.tsv
```

### 3. Apply the model
Now, the mailicious attacker can assess if *G* and *I* belongs to the same person by first computing their LLR:
```bash
Rscript llr_computation.r --pgs Example_data/genome_pgs.tsv \
    --pheno Example_data/individual_phenotypes.tsv \
    --qnorm F \
    --r2 Example_output/r2.tsv.gz \
    --ce Example_output/ce.tsv.gz \
    --llr Example_output/llr.individual_x_genome.tsv.gz
```
and then convert it to a probability of a match:
```bash
Rscript llr2probas.r --llr Example_output/llr.individual_x_genome.tsv.gz \
    --moments Example_output/moments.tsv \
    --probas Example_output/probas.individual_x_genome.tsv.gz \
    --round 10
```

The proba of *I* and *G* of belonging to the same individual is stored in **Example_output/probas.individual_x_genome.tsv.gz**.


## Scripts
- **compute_ce_cg_r2.r** \
    Compute the environmental (Ce) and genetic correlation (Cg) between each phenotype and their variance explained by genetics (r2) based on a given dtaset of phenotypes and polygenic scores.
    * *--pheno* Input matrix jof phenotypes. First column is the ID of the individual + One column per phenotype, one row per individual.
    * *--pgs* Input matrix of polygenic scores. Same format as *--pheno*.
    * *--ce* Output path for the environmental correlation between the phenotypes. Matrix of size #phenotypes x #phenotypes.
    * *--cg* Output path for the genetic correlation between the phenotypes. Matrix of size #phenotypes x #phenotypes.
    * *--r2* Output path for the variance explained by each phenotype. Matrix with #phenotypes rows and two columns: "pheno", containing the phenotype name, and "r2", containing the corresponding variance explained.

- **llr_computation.r** \
    Compute Log-likelihood ratios (LLR).
    * *--ce* Input environmental correlation between phenotypes.
    * *--r2* Input variance explained between the phenotypes.
    * *--pheno* Input matrix of phenotypes. Format described in **compute_ce_cg_r2.r**.
    * *--pgs* Input matrix of polygenic scores. Format described in **compute_ce_cg_r2.r**.
    * *--llr* Output path for the computed LLR. Matrix of #individuals rows and two columns: "IID", containing the ID of the individual, and "llr", corresponding the the log-likelihood ratios.

- **moments_supervised.r** \
    Compute the moments of the LLR distribution (training of the model) using the **supervised approach** described in the paper.
    * *--llr_h1* LLR computed between a *--pheno* matrix and a *--pgs* matrix where individuals ID per row were the same.
    * *--llr_h0* LLR computed between a *--pheno* matrix and a *--pgs* matrix where individuals ID per row were different.
    * *--moments* Output path for the estimated moments of the distribution of LLR under H0 and H1.

- **moments_unsupervised.r** \
    Compute the moments of the LLR distributions (training of the model) using the **unsupervised approach** described in the paper.
    * *--r2* Input variance explained for each phenotype.
    * *--ce* Input environmental correlation between the phenotypes.
    * *--cg* Input genetic correlation between the phenotypes.
    * *--moments* Output path for the estimated moments of the distribution of LLR under H0 and H1.

- **llr2probas.r** \
    Convert LLR into probability of a match (Pr(G=I | LLR) in the paper).
    * *--moments* Path to the trained model (output of the supervised or unsupervised moments).
    * *--llr* LLR computed between a *--pheno* matrix and a *--pgs* matrix of people suspected to be the same.
    * *--probas* Output file for probabilities.
    * *--round (optional)* Number of digits to use in *--probas* file.

## Analysis
The following folders each correspond to an analysis in the paper:
- **Precision_recall_per_phenotype**: assessment of the precision-recall of our method.
- **Realistic_scenario**: re-assessment of the preicision-recall in a realistic scenario.
- **Apoe_inference**: aims at inferring whether individuals were carrier of the APOE-e4 haplotype using re-identification by phenotypic prediction.
- **Comparison_idefix**: comparison of IDEFIX with our method.
- **Participation**: aims at inferring whether an individual was part of the biobank using re-identification by phenotypic prediction.

The code in the folder **Compute_variance_explained** and **LDSC** was used to generate necessary data for the analysis.
