================================================================================
ZmL HUMANIZATION — COMPLETE ANALYSIS PIPELINE (from raw reads)
================================================================================
Run the scripts IN ORDER. Each writes outputs that the next one reads.
Everything lands in the folders created by 00.

  00_setup.R            Install/load packages, create folder structure, config
  01_dada2.R            Raw FASTQ -> ASV table + taxonomy -> phyloseq object
  02_alpha.R            Alpha diversity (NON-normalized), stats, baseline check
  03_beta.R             CSS + ConQuR -> Bray-Curtis -> PCoA/PERMANOVA
  04_deseq2.R           Differential abundance (batch-adjusted), enrichment
  05_targets.R          10 target genera: trajectories, Wilcoxon, humanization score
  06_composition.R      Stacked-bar composition figures (stool + larvae)
  07_supplementary.R    Build all styled supplementary Excel tables

FOLDER LAYOUT (created by 00_setup.R):
  0_raw/                <- PUT YOUR RAW FASTQ HERE (or point config to them)
  1_dada2/              intermediate DADA2 objects
  2_phyloseq/           ps_master.rds  (the single source of truth)
  3_stats/              all CSV stat outputs
  4_figures/            PNG + SVG figures
  5_excel/              supplementary Excel files

KEY METHODS DECISIONS (locked, per your methods text):
  - Alpha diversity: computed on NON-normalized ASV counts
  - Beta diversity : CSS normalization (metagenomeSeq) + ConQuR batch correction
  - Differential abundance: DESeq2, design ~ Run + Diet (Run = batch)
  - Primers: 515F/806R (V4); truncLen 235/190; SILVA v138.1 Nr99
================================================================================
