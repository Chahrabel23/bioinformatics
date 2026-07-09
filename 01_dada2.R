# ============================================================================
# 01_dada2.R  —  Raw FASTQ -> ASV table + taxonomy -> phyloseq object
# Processes Run_1, Run_2, Run_3 (larvae, per-run error learning) + Stools.
# Output: 2_phyloseq/ps_master.rds
# ============================================================================
cfg <- readRDS("~/desktop/analysis_repeat_16s/.ZmL_config.rds")
list2env(cfg, envir = environment())
setwd(PROJECT_DIR)

library(dada2); library(phyloseq); library(tidyverse); library(Biostrings)
set.seed(SEED)

# sample name = filename with the _1.fastq.gz / _2.fastq.gz suffix removed
strip_suffix <- function(f) sub("_[12]\\.fastq\\.gz$", "", basename(f))

process_folder <- function(path, label) {
  cat("\n=== Processing", label, "(", path, ") ===\n")
  fnFs <- sort(list.files(path, pattern = FWD_PATTERN, full.names = TRUE))
  fnRs <- sort(list.files(path, pattern = REV_PATTERN, full.names = TRUE))
  cat("  Forward files:", length(fnFs), " Reverse files:", length(fnRs), "\n")
  if (length(fnFs) == 0) stop("No files found in ", path,
                              " — check FWD_PATTERN/REV_PATTERN in 00_setup.R")
  stopifnot(length(fnFs) == length(fnRs))

  sample.names <- strip_suffix(fnFs)
  cat("  Samples:", length(sample.names), "\n")

  filt_dir <- file.path("1_dada2", gsub(" ","_",label))
  dir.create(filt_dir, showWarnings = FALSE, recursive = TRUE)
  filtFs <- file.path(filt_dir, paste0(sample.names, "_F_filt.fastq.gz"))
  filtRs <- file.path(filt_dir, paste0(sample.names, "_R_filt.fastq.gz"))
  names(filtFs) <- sample.names; names(filtRs) <- sample.names

  out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs,
                       truncLen = TRUNC_LEN, maxN = 0, maxEE = MAX_EE,
                       truncQ = TRUNC_Q, rm.phix = TRUE,
                       compress = TRUE, multithread = TRUE)

  # keep only files that survived filtering (some may be dropped if empty)
  keep <- file.exists(filtFs)
  filtFs <- filtFs[keep]; filtRs <- filtRs[keep]

  errF <- learnErrors(filtFs, multithread = TRUE)
  errR <- learnErrors(filtRs, multithread = TRUE)
  dadaFs <- dada(filtFs, err = errF, multithread = TRUE)
  dadaRs <- dada(filtRs, err = errR, multithread = TRUE)
  mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose = TRUE)
  st <- makeSequenceTable(mergers)
  cat("  ASVs in", label, ":", ncol(st), "\n")
  st
}

# ---- Process each larvae run separately (per-run error models) ----
seqtabs <- list()
for (run_name in names(RUN_FOLDERS))
  seqtabs[[run_name]] <- process_folder(RUN_FOLDERS[[run_name]], run_name)

# ---- Process stool samples ----
if (dir.exists(STOOL_FOLDER))
  seqtabs[["Stools"]] <- process_folder(STOOL_FOLDER, "Stools")

# ---- Merge, remove chimeras ----
seqtab <- mergeSequenceTables(tables = seqtabs)
cat("\nMerged ASVs:", ncol(seqtab), "\n")
seqtab.nochim <- removeBimeraDenovo(seqtab, method = "consensus",
                                    multithread = TRUE, verbose = TRUE)
cat("After chimera removal:", ncol(seqtab.nochim),
    "| reads retained:", round(sum(seqtab.nochim)/sum(seqtab)*100,2), "%\n")

# ---- Taxonomy ----
taxa <- assignTaxonomy(seqtab.nochim, SILVA_TRAIN, multithread = TRUE)
taxa <- addSpecies(taxa, SILVA_SPEC)

# ============================================================================
# Metadata parser — matched to YOUR names, e.g.:
#   NG-A7582_V4a_T0_C2_RUN1_libLAW4657    (larvae; C=Control, S=Experimental)
#   NG-A7691_V4a_T28_C1_Run1_libLAW8739   (note lower-case Run1)
#   <stool naming>                        (Sample_Type = Stool)
# ============================================================================
samples <- rownames(seqtab.nochim)

parse_meta <- function(nm) {
  tp  <- str_extract(nm, "T\\d+")
  run <- str_extract(nm, regex("RUN\\d", ignore_case = TRUE))
  run <- if (!is.na(run)) paste("Run", str_extract(run, "\\d")) else NA
  # diet: _C<digit> = Control, _S<digit> = Experimental (larvae only)
  diet <- case_when(
    str_detect(nm, "_C\\d") ~ "Control",
    str_detect(nm, "_S\\d") ~ "Experimental",
    TRUE ~ NA_character_
  )
  # stool samples: no T#/RUN# larvae pattern, or explicit stool tag
  is_stool <- is.na(tp) | is.na(run) | str_detect(nm, regex("stool|NS_|pool", ignore_case=TRUE))
  data.frame(SampleID = nm,
             Timepoint = ifelse(is_stool, NA, tp),
             Run = ifelse(is_stool, NA, run),
             Diet = ifelse(is_stool, NA, diet),
             Sample_Type = ifelse(is_stool, "Stool", "Larvae"),
             stringsAsFactors = FALSE)
}
meta <- do.call(rbind, lapply(samples, parse_meta))
rownames(meta) <- meta$SampleID

cat("\n============================================================\n")
cat("METADATA PARSE CHECK — VERIFY THIS IS CORRECT BEFORE PROCEEDING\n")
cat("============================================================\n")
print(meta, row.names = FALSE)
cat("\nLarvae: Diet x Run:\n")
print(table(meta$Diet, meta$Run, useNA = "always"))
cat("\nSample_Type counts:\n"); print(table(meta$Sample_Type))
cat("\nTimepoints (larvae):\n")
print(table(meta$Timepoint[meta$Sample_Type=="Larvae"]))
cat("============================================================\n")
cat("If anything above is wrong, STOP and fix parse_meta() before continuing.\n\n")

# ---- Build phyloseq ----
ps <- phyloseq(otu_table(seqtab.nochim, taxa_are_rows = FALSE),
               tax_table(taxa), sample_data(meta))
dna <- DNAStringSet(taxa_names(ps)); names(dna) <- taxa_names(ps)
ps <- merge_phyloseq(ps, dna)
taxa_names(ps) <- paste0("ASV", seq(ntaxa(ps)))

# ---- Filter ----
ps <- subset_taxa(ps, Kingdom %in% c("Bacteria","Archaea"))
ps <- subset_taxa(ps, is.na(Order)  | Order  != "Chloroplast")
ps <- subset_taxa(ps, is.na(Family) | Family != "Mitochondria")
ps <- subset_taxa(ps, !is.na(Phylum))
ps <- filter_taxa(ps, function(x) sum(x) >= 10 & sum(x > 0) >= 2, TRUE)

cat("Final object:\n"); print(ps)
cat("Depth summary:\n"); print(summary(sample_sums(ps)))
saveRDS(ps, "2_phyloseq/ps_master.rds")
write.csv(data.frame(Sample = names(sample_sums(ps)), FinalReads = sample_sums(ps)),
          "3_stats/read_tracking_final.csv", row.names = FALSE)
cat("\nSaved: 2_phyloseq/ps_master.rds\n")
