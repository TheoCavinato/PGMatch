# PGMatch (Phenotype-Genotype Match using polygenic scores)

Code supporting the paper entitled "Assessing the real threat of genome re-identification by polygenic predictions".
The main directory contains the scripts an attacker could use to re-identify a genome.
These R scripts together form the **PGMatch** software described in the paper.
The **Analysis/** directory contains the scripts we used to perform the analyses reported in the paper.

## Quickstart
Here is a step-by-step explanation of how our method works based on an example dataset.
To try it, please first install the following **dependencies** in R:
``` install.packages("argparse", "corpcor", "data.table", "MASS", "moments", "mvtnorm", "PearsonDS") ```

### Example dataset
Our paper aims to assess whether re-identification by phenotypic prediction is possible in realistic scenarios.
In this short example, we imagine a malicious individual has access to **50** phenotypes of an individual *I*, stored in **Example_data/individual_phenotypes.tsv.**
This malicious individual also got access to the genotypes of a genome *G*, and would like to know whether *G* belongs to *I*.
They compute the polygenic scores (PGS) for each phenotype of *I* on *G* and stored them in **Example_data/genome_pgs.tsv**

First, the malicious individual needs to learn how different the PGS of a genome and the phenotype of an individual are.
Fortunately, they have access to a biobank containing both genomes and their actual phenotypes.
They compute the polygenic scores for these phenotypes on each genome, and store the result in **Example_data/biobank_pgs.tsv**.
The corresponding actual phenotypes for each genome are stored in **Example_data/biobank_phenotypes.tsv**.

To generate this data, just use the script we provide:
```bash
Rscript Example_data/generate_example_data.r
```

### 1. Computing necessary statistics.
Using the biobank, the attacker first computes the environmental correlation (Ce), genetic correlation (Cg), and variance explained by genetics (r²) for each phenotype, based on a given dataset of phenotypes and polygenic scores.
```bash
mkdir -p Example_output/
Rscript compute_ce_cg_r2.r --pgs Example_data/biobank_pgs.tsv \
    --pheno Example_data/biobank_phenotypes.tsv \
    --r2 Example_output/r2.tsv.gz \
    --ce Example_output/ce.tsv.gz \
    --cg Example_output/cg.tsv
```

### 2. Model trainnig
Once the attacker has learned these parameters, they can estimate the distribution of the log-likelihood ratio (LLR) in matches and mismatches.
Distribution for matches:
```bash
Rscript llr_computation.r --pgs Example_data/biobank_pgs.tsv \
    --pheno Example_data/biobank_phenotypes.tsv \
    --r2 Example_output/r2.tsv.gz \
    --ce Example_output/ce.tsv.gz \
    --llr Example_output/llr.h1.tsv.gz
```
Distribution for mismatches:
```bash
head -n 1 Example_data/biobank_pgs.tsv > Example_data/biobank_pgs.shuf.tsv
tail -n +2 Example_data/biobank_pgs.tsv | shuf >> Example_data/biobank_pgs.shuf.tsv
Rscript llr_computation.r --pgs Example_data/biobank_pgs.shuf.tsv \
    --pheno Example_data/biobank_phenotypes.tsv \
    --r2 Example_output/r2.tsv.gz \
    --ce Example_output/ce.tsv.gz \
    --llr Example_output/llr.h0.tsv.gz

```
Then, they can estimate these distributions:
```bash
Rscript moments_supervised.r --llr_h0 Example_output/llr.h0.tsv.gz \
    --llr_h1 Example_output/llr.h1.tsv.gz \
    --moments Example_output/moments.tsv
```

### 3. Apply the model
Now, the malicious attacker can assess whether *G* and *I* belong to the same person by first computing their LLR:
```bash
Rscript llr_computation.r --pgs Example_data/genome_pgs.tsv \
    --pheno Example_data/individual_phenotypes.tsv \
    --qnorm F \
    --r2 Example_output/r2.tsv.gz \
    --ce Example_output/ce.tsv.gz \
    --llr Example_output/llr.individual_x_genome.tsv.gz
```

and then converting it into a probability of a match:

```bash
Rscript llr2probas.r --llr Example_output/llr.individual_x_genome.tsv.gz \
    --moments Example_output/moments.tsv \
    --probas Example_output/probas.individual_x_genome.tsv.gz \
    --round 10
```

The probability that *I* and *G* belong to the same individual is stored in **Example_output/probas.individual_x_genome.tsv.gz**.


## Scripts
- **compute_ce_cg_r2.r** \
    Computes the environmental (Ce) and genetic correlation (Cg) between each phenotype and the variance explained by genetics (r²) based on a given dataset of phenotypes and polygenic scores.
    * *--pheno* Input matrix of phenotypes. First column: individual ID; one column per phenotype; one row per individual.
    * *--pgs* Input matrix of polygenic scores. Same format as --pheno.
    * *--ce* Output path for the environmental correlation between the phenotypes. Matrix of size #phenotypes x #phenotypes.
    * *--cg* Output path for the genetic correlation between the phenotypes. Matrix of size #phenotypes x #phenotypes.
    * *--r2* Output path for the variance explained by each phenotype. Matrix with #phenotypes rows and two columns: "pheno" (phenotype name) and "r2" (variance explained).

- **llr_computation.r** \
    Computes Log-likelihood ratios (LLR).
    * *--ce* Input environmental correlation between phenotypes.
    * *--r2* Input variance explained between the phenotypes.
    * *--pheno* Input matrix of phenotypes. Format described in **compute_ce_cg_r2.r**.
    * *--pgs* Input matrix of polygenic scores. Format described in **compute_ce_cg_r2.r**.
    * *--llr* Output path for the computed LLR. Matrix of #individuals rows and two columns: "IID" (individual ID) and "llr" (log-likelihood ratios).

- **moments_supervised.r** \
    Computes the moments of the LLR distribution (model training) using the **supervised approach** described in the paper.
    * *--llr_h1* LLR computed between a *--pheno* matrix and a *--pgs* matrix where IDs per row match.
    * *--llr_h0* LLR computed between a *--pheno* matrix and a *--pgs* matrix where IDs per row differ.
    * *--moments* Output path for the estimated moments of the LLR distribution under H0 and H1.

- **moments_unsupervised.r** \
    Computes the moments of the LLR distribution (model training) using the **unsupervised approach** described in the paper.
    * *--r2* Input variance explained for each phenotype.
    * *--ce* Input environmental correlation between the phenotypes.
    * *--cg* Input genetic correlation between the phenotypes.
    * *--moments* Output path for the estimated moments of the distribution of LLR under H0 and H1.

- **llr2probas.r** \
    Converts LLR into the probability of a match (Pr(G=I | LLR), as described in the paper).
    * *--moments* Path to the trained model (output of supervised or unsupervised moments).
    * *--llr* LLR computed between a *--pheno* matrix and a *--pgs* matrix of people suspected matches.
    * *--probas* Output file for probabilities.
    * *--round (optional)* Number of digits to use in the *--probas* file.

## Analysis
The following folders each correspond to an analysis in the paper:
- **Precision_recall_per_phenotype**: assessment of the precision-recall of our method.
- **Realistic_scenario**: re-assessment of preicision-recall in a realistic scenario.
- **Apoe_inference**: inference of whether individuals carry the APOE-e4 haplotype using re-identification by phenotypic prediction.
- **Comparison_idefix**: comparison of IDEFIX with our method.
- **Participation**: inference of whether an individual was part of a biobank using re-identification by phenotypic prediction.

The code in the folder **Compute_variance_explained** and **LDSC** was used to generate necessary data for the analysis.
