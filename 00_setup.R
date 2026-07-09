# ============================================================================
# 00_setup.R  —  Packages, folders, and global configuration
# Run this ONCE before anything else. Edit the CONFIG block for your paths.
# ============================================================================

# ---------------------------- CONFIG (EDIT ME) ------------------------------
PROJECT_DIR <- "~/desktop/analysis_repeat_16s"   # your working directory
RAW_DIR     <- file.path(PROJECT_DIR, "0_raw")   # where the FASTQ files live
SILVA_TRAIN <- file.path(PROJECT_DIR, "silva_nr99_v138.1_train_set.fa.gz")
SILVA_SPEC  <- file.path(PROJECT_DIR, "silva_species_assignment_v138.1.fa.gz")

# Your folders are Run_1, Run_2, Run_3, Stools (with underscores).
RUN_FOLDERS <- list(
  "Run 1" = file.path(RAW_DIR, "Run_1"),
  "Run 2" = file.path(RAW_DIR, "Run_2"),
  "Run 3" = file.path(RAW_DIR, "Run_3")
)
STOOL_FOLDER <- file.path(RAW_DIR, "Stools")   # human stool samples

# Your files end in _1.fastq.gz / _2.fastq.gz
FWD_PATTERN <- "_1.fastq.gz$"
REV_PATTERN <- "_2.fastq.gz$"

# DADA2 truncation (from your methods)
TRUNC_LEN   <- c(235, 190)   # forward, reverse
MAX_EE      <- c(2, 2)
TRUNC_Q     <- 2

TIMEPOINTS  <- c("T0","T7","T14","T21","T28","T35","T42","T49","T56")
DIET_COLS   <- c("Control"="steelblue","Experimental"="tomato")
SEED        <- 42
# ----------------------------------------------------------------------------

setwd(PROJECT_DIR)

for (d in c("0_raw","1_dada2","2_phyloseq","3_stats","4_figures","5_excel"))
  dir.create(file.path(PROJECT_DIR, d), showWarnings = FALSE, recursive = TRUE)

if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
bioc_pkgs <- c("dada2","phyloseq","DESeq2","metagenomeSeq")
cran_pkgs <- c("tidyverse","vegan","ggplot2","openxlsx","RColorBrewer",
               "scales","patchwork","rstatix","doParallel","remotes")
for (p in cran_pkgs)
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
for (p in bioc_pkgs)
  if (!requireNamespace(p, quietly = TRUE)) BiocManager::install(p, update = FALSE)
if (!requireNamespace("ConQuR", quietly = TRUE))
  remotes::install_github("wdl2459/ConQuR")

saveRDS(mget(c("PROJECT_DIR","RAW_DIR","SILVA_TRAIN","SILVA_SPEC","RUN_FOLDERS",
               "STOOL_FOLDER","FWD_PATTERN","REV_PATTERN",
               "TRUNC_LEN","MAX_EE","TRUNC_Q","TIMEPOINTS","DIET_COLS","SEED")),
        file.path(PROJECT_DIR, ".ZmL_config.rds"))
cat("Setup complete. Config saved.\n")
