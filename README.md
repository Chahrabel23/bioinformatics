# Bioinformatics Pipelines

Reproducible scripts and pipelines for **bacterial genomics, phylogenomics, and metagenomics**, developed and used across my research at the University of Bern (IFIK & IVB). They cover the full path from raw sequencing reads to annotated genomes, phylogenies, and community-diversity statistics, for both **short-read (Illumina)** and **long-read (Oxford Nanopore, PacBio)** data.

**Chahrazed Belhout**, DVM, PhD — Genomics & Bioinformatics
📍 Bern, Switzerland · ✉️ chahrazed.belhout@unibe.ch

---

## Overview

These pipelines were built for isolate whole-genome sequencing, comparative and phylogenomic analysis (including two novel species descriptions), and shotgun-metagenomics MAG recovery. They run on Linux with `conda`-managed environments and are set up for a **SLURM** cluster (University of Bern, UBELIX).

## Environment

| | |
|---|---|
| **Languages** | Bash, R, Python |
| **Compute** | Linux · SLURM (UBELIX HPC) · conda |
| **Read types** | Illumina (short-read); Oxford Nanopore & PacBio (long-read) |

## Repository structure

### 1 · Quality control & preprocessing
| Script | Tool | Purpose |
|---|---|---|
| `fastqc.sh` | FastQC | Read quality assessment (Illumina) |
| `trimmomatic.sh` | Trimmomatic | Adapter/quality trimming (short-read) |
| `porechop.sh` | Porechop | Adapter removal (Nanopore) |
| `filtlong.sh` | Filtlong | Length/quality filtering (long-read) |
| `host_decontamination.sh` | — | Remove host reads before assembly |

### 2 · Genome assembly
| Script | Tool | Purpose |
|---|---|---|
| `unicycler_spades.sh` | Unicycler / SPAdes | Short-read & hybrid isolate assembly |
| `hybrid_assembly_pipeline.sh` | — | Combined short + long-read assembly |
| `longread_assembly_pipeline.sh` | — | Long-read assembly workflow |

### 3 · Assembly QC
| Script | Tool | Purpose |
|---|---|---|
| `quast_nanopore.sh` | QUAST | Assembly metrics |
| `busco.sh` | BUSCO | Assembly completeness |
| `checkm.sh` | CheckM | Genome/MAG completeness & contamination |

### 4 · Annotation
| Script | Tool | Purpose |
|---|---|---|
| `bakta.sh` | Bakta | Genome annotation (default) |
| `prokka.sh` | Prokka | Genome annotation (alternative) |

### 5 · Typing, AMR & mobile elements
| Script | Tool | Purpose |
|---|---|---|
| `mlst.sh` | mlst | Sequence typing |
| `amrfinder.sh` | AMRFinderPlus | Acquired AMR genes & point mutations |
| `resfinder.sh` | ResFinder | Acquired resistance genes |
| `plasmidfinder.sh` | PlasmidFinder | Plasmid replicon typing |
| `blast.sh` | BLAST | Custom sequence searches |

### 6 · Comparative, structural & phylogenomic analysis
| Script | Tool | Purpose |
|---|---|---|
| `syri.sh` | SyRI | Structural rearrangements & synteny between genomes |
| `snippy_reads.sh` | Snippy | SNP calling from reads |
| `snippy_contigs.sh` | Snippy | SNP calling from assemblies |

## Selected applications

- **Complete reference genomes** assembled and annotated from hybrid short- + long-read data (*Paenimyroides ceti*, *Pseudomonas* sp., MRSA ST630).
- **Two novel species descriptions** — *Macrococcus animalis* sp. nov. and *Macrococcus equi* sp. nov. — supported by comparative and phylogenomic analysis.
- **Molecular epidemiology** of resistant Staphylococcaceae, mapping genetic diversity and clonal dissemination.

## Notes

- Paths, databases, and resource settings are placeholders — adjust to your system.
- Reference databases (Bakta, GTDB-Tk, Kraken2, SILVA) must be downloaded separately.
- Related workflows (shotgun-metagenomics MAG classification with GTDB-Tk; 16S rRNA analysis with DADA2 and microbiome diversity statistics in R) are maintained in companion repositories.

## Publications

Full list on [PubMed](https://pubmed.ncbi.nlm.nih.gov/?term=chahrazed+belhout).

---

*Feel free to open an issue or reach out with questions.*
