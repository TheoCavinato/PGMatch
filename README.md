# Re-iodentification by polygenic predictions

Code supporting the paper entitled "Assessing the real threat of re-identification by polygenic predictions". \
In the main directory are the scripts an attacker could use to re-identify a genome. \
In the **Analysis/** directory are the scripts we used to perform the analysis reported in the paper

## Quickstart

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
One folder per analysis performed in the paper.
