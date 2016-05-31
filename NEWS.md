# stackr v.0.2.8
* bug fix in `tidy_genomic_data` while using data.table::melt.data.table instead 
of tidyr::gather, and forgot to 
(i) add variable.factor = FALSE when melting the vcf and (ii) use as_data_frame
at the end of the melting to be able to continue working with dplyr verbs.


# stackr v.0.2.7
* Added a `NEWS.md` file to track changes to the package.
* New function: `individuals2strata`. Several functions in **stackr** and 
[assigner] (https://github.com/thierrygosselin/assigner) requires a `strata`
argument, i.e. a data frame with the individuals and associated groupings. 
You can do it manually, however, if your individuals have a consistent naming scheme 
(e.g. SPECIES-POPULATION-MATURITY-YEAR-ID = CHI-QUE-ADU-2014-020), 
use this function to rapidly create a strata file.
* New function: `tidy_genomic_data`. 
Transform common genomic dataset format in a tidy data frame. Used internally in
**stackr** and [assigner] (https://github.com/thierrygosselin/assigner)
and might be of interest for users.
* New function: `read_long_tidy_wide`. Read genomic data frames in long/tidy and wide format.
Used internally in **stackr** and [assigner] (https://github.com/thierrygosselin/assigner)
and might be of interest for users.
* New function: `stackr_imputations_module`. 
Map-independent imputation of missing genotype using Random Forest
or the most frequent category. Impute genotypes or alleles. 
Used internally in **stackr** and [assigner] (https://github.com/thierrygosselin/assigner)
and might be of interest for users.
* New function: `find_duplicate_id`
Compute pairwise genome similarity to highligh potential duplicate individuals.


# stackr v.0.2.6
* dart2df_genind_plink: swiss army knife tool to prepare DArT output file (wide 
or binary format) for population genetics analysis. Import, filter and transform 
a DArT output file to different format: tidy data frame of genotypes, genind object 
and/or PLINK `tped/tfam` format. Map-independent imputation also available.


# stackr v.0.2.5
* vcf2plink: to easily convert a VCF file created in STACKS to a PLINK input 
file (tped/tfam format). This function comes with the commonly used arguments 
in **stackr**: map-independent imputation, whitelist, blacklist, common marker filtering, etc.

* data_pruning: to prune your dataset with whitelist, blacklist of individuals, 
erase genotypes, use common markers and other filtering (see function argument 
while waiting for the upcomming documentation).

# stackr v.0.2.4
* updated the vcf_imputation function for the commonly used arguments in **stackr**.

# stackr v.0.2.3
* vcf2dadi: to easily convert a VCF file created in STACKS to a dadi input file.
This function comes with the commonly used arguments in **stackr**: 
map-independent imputation, whitelist, blacklist, common marker filtering, etc.

# stackr v.0.2.2
* vcf2genepop: to easily convert a VCF file created in STACKS to a genepop input file.
This function comes with the commonly used arguments in **stackr**: 
map-dependent imputation, whitelist, blacklist, etc. For the haplotype version, see
haplo2genepop.

# stackr v.0.2.1
* 'read_stacks_vcf' can now use a whitelist or blacklist of loci that works with CHROM and/or SNP and/or LOCUS.
* 'filter_maf', 'filter_fis', 'filter_het' and 'filter_genotype_likelihood' now works by haplotypes or SNP.

# stackr v.0.2.0
Introducing several new functions: 
* vcf2betadiv: to easily convert a VCF file created in STACKS to a betadiv input file.
* vcf2genind: same as haplo2genind but works with SNP instead of haplotypes.
* vcf2hierfstat: same as haplo2hierfstat but works with SNP instead of haplotypes.

# stackr v.0.1.5
Introducing *haplo2gsi_sim* function.
* Conversion of STACKS haplotypes file into a gsi_sim data input file.
* Markers can be subsampled.
* Map-independent imputations using Random Forest or the most frequent allele are options also available for this function.
* [gsi_sim] (https://github.com/eriqande/gsi_sim) is a tool developed by Eric C. Anderson for doing and simulating genetic stock identification.

# stackr v.0.1.4
Introducing *haplo2fstat* function.
Conversion of STACKS haplotypes file into a hierfstat object and fstat file.
Access all the functions in the R package [hierfstat] (https://github.com/jgx65/hierfstat).

# stackr v.0.1.3
Map-independent imputations of a VCF file created by STACKS. 
Two options are available for imputations: using Random Forest or the most frequent allele.

Before imputations, the VCF file can be filtered with:

* a whitelist of loci (to keep only specific loci...)
* a blacklist of individuals (to remove individuals or entire populations...)
* also, a list of genotypes with bad coverage and/or genotype likelihood can be supplied to erase the genotypes before imputations (for more details look at the function: blacklist_erase_genotype).

# stackr v.0.1.2
**The *summary_haplotypes* function now outputs:**
* Putative paralogs, consensus, monomorphic and polymorphic loci
* The haplotype statistics for the observed and expected homozygosity and 
heterozygosity
* Wright’s inbreeding coefficient (Fis)
* Proxy measure of the realized proportion of the genome that is identical
by descent (IBDG). The FH measure is based on the excess in the observed number
of homozygous genotypes within an individual relative to the mean number of 
homozygous genotypes expected under random mating (Keller et al., 2011; 
Kardos et al., 2015).
* Nucleotide diversity (Pi), considering the consensus loci in the catalog 
(i.e. reads with no variation between population). It's Nei & Li (1979) 
function, adapted to the GBS reality.

Keller MC, Visscher PM, Goddard ME. 2011. Quantification of inbreeding due to 
distant ancestors and its detection using dense single nucleotide polymorphism
data. Genetics, 189, 237–249.

Kardos M, Luikart G, Allendorf FW. 2015. Measuring individual inbreeding in the 
age of genomics: marker-based measures are better than pedigrees. 
Heredity, 115, 63–72.

Nei M, Li WH. 1979. Mathematical model for studying genetic variation in terms
of restriction endonucleases. Proceedings of the National Academy of Sciences 
of the United States of America, 76, 5269–5273.

**The *haplo2colony* function**
* Converts the file to the required *COLONY* input file
* Can filter the haplotypes file with a whitelist of loci 
and a blacklist of individuals
* Can impute the data with Random Forest or the most frequent category
* Use the *print.all.colony.opt* to output all COLONY options to the file.
This however requires manual curation of the file to work directly with COLONY. 