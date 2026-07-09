# ============================================================================
# 07_supplementary.R  —  Build all styled supplementary Excel tables
# Reads the CSVs written by scripts 02-05 and the phyloseq object.
# Produces: SupplementaryTable1/2/3.xlsx in 5_excel/, one unified style.
# ============================================================================
cfg <- readRDS("~/desktop/analysis_repeat_16s/.ZmL_config.rds")
list2env(cfg, envir = environment()); setwd(PROJECT_DIR)

library(phyloseq); library(tidyverse); library(openxlsx)

NAVY <- "#1F3864"
hdr  <- createStyle(fontColour="#FFFFFF", fgFill=NAVY, halign="center",
                    valign="center", textDecoration="bold", border="TopBottomLeftRight",
                    borderColour="#BFBFBF", wrapText=TRUE)
titl <- createStyle(fontColour=NAVY, textDecoration="bold", fontSize=12)
subt <- createStyle(fontColour="#595959", textDecoration="italic", fontSize=9)
ital <- createStyle(textDecoration="italic")

add_tab <- function(wb, sheet, title, subtitle, df, italic_col1=FALSE) {
  addWorksheet(wb, sheet, gridLines=FALSE)
  writeData(wb, sheet, title, startRow=1); addStyle(wb, sheet, titl, 1, 1)
  writeData(wb, sheet, subtitle, startRow=2); addStyle(wb, sheet, subt, 2, 1)
  writeData(wb, sheet, df, startRow=4, headerStyle=hdr, borders="all",
            borderColour="#DDDDDD")
  if (italic_col1)
    addStyle(wb, sheet, ital, rows=5:(4+nrow(df)), cols=1, gridExpand=TRUE, stack=TRUE)
  setColWidths(wb, sheet, cols=1:ncol(df), widths="auto")
  freezePane(wb, sheet, firstActiveRow=5)
}

ps <- readRDS("2_phyloseq/ps_master.rds")

# ================= SUPPLEMENTARY TABLE 1 — microbiome data =================
wb1 <- createWorkbook()
tax <- as.data.frame(tax_table(ps)) %>% rownames_to_column("ASV")
add_tab(wb1, "S1.1 Taxonomy", "Supplementary Table S1.1 — ASV taxonomy",
        "Taxonomic classification of all ASVs (SILVA v138.1).", tax)

otu <- as.data.frame(t(as(otu_table(ps),"matrix"))) %>% rownames_to_column("ASV")
add_tab(wb1, "S1.2 ASV counts", "Supplementary Table S1.2 — ASV count table",
        "Raw read counts per ASV per sample.", otu)

relg <- psmelt(tax_glom(transform_sample_counts(subset_samples(ps,Sample_Type=="Larvae"),
        function(x) x/sum(x)), "Genus", NArm=FALSE)) %>%
  mutate(Genus=ifelse(is.na(Genus),"Unclassified",as.character(Genus))) %>%
  group_by(Sample, Diet, Run, Timepoint, Genus) %>%
  summarise(Abundance=sum(Abundance), .groups="drop") %>%
  pivot_wider(names_from=Genus, values_from=Abundance, values_fill=0)
add_tab(wb1, "S1.3 Genus rel abund", "Supplementary Table S1.3 — Genus relative abundance",
        "Relative abundance (0-1) per larval sample.", as.data.frame(relg))
saveWorkbook(wb1, "5_excel/SupplementaryTable1.xlsx", overwrite=TRUE)

# ================= SUPPLEMENTARY TABLE 2 — engraftment =================
wb2 <- createWorkbook()
add_tab(wb2, "S2.1 Inoculum", "Supplementary Table S2.1 — Target genera in inoculum",
        "Donor range and pooled-inoculum abundance of the ten target genera.",
        read.csv("3_stats/S2.1_target_inoculum.csv"), italic_col1=TRUE)
add_tab(wb2, "S2.2 Detection", "Supplementary Table S2.2 — Target genus detection",
        "Detection of each target genus in larvae.",
        read.csv("3_stats/S2.2_detection.csv"), italic_col1=TRUE)
add_tab(wb2, "S2.3 Wilcoxon", "Supplementary Table S2.3 — Wilcoxon tests",
        "Per-genus control vs experimental (BH-corrected).",
        read.csv("3_stats/S2.3_wilcoxon.csv"), italic_col1=TRUE)
add_tab(wb2, "S2.4 Trajectories", "Supplementary Table S2.4 — Engraftment trajectories",
        "Mean +/- SE per genus, diet group, and timepoint.",
        read.csv("3_stats/S2.4_trajectories.csv"), italic_col1=TRUE)
add_tab(wb2, "S2.5 Humanization", "Supplementary Table S2.5 — Humanization score",
        "Per-sample sum of the ten target genera.",
        read.csv("3_stats/S2.5_humanization_score.csv"))
add_tab(wb2, "S2.6 DESeq2", "Supplementary Table S2.6 — Differential abundance (DESeq2)",
        "Genera differing between groups (~Run+Diet, padj<0.05).",
        read.csv("3_stats/deseq2_experimental_vs_control.csv") %>% filter(padj<0.05),
        italic_col1=FALSE)
saveWorkbook(wb2, "5_excel/SupplementaryTable2.xlsx", overwrite=TRUE)

# ================= SUPPLEMENTARY TABLE 3 — diversity =================
wb3 <- createWorkbook()
add_tab(wb3, "S3.1 Alpha diversity", "Supplementary Table S3.1 — Per-sample alpha diversity",
        "Observed richness and Shannon index (non-normalized counts).",
        read.csv("3_stats/alpha_diversity.csv"))
add_tab(wb3, "S3.2 Alpha by timepoint", "Supplementary Table S3.2 — Alpha diversity by timepoint",
        "Per-timepoint control vs experimental (Wilcoxon, BH).",
        read.csv("3_stats/alpha_by_timepoint.csv"))
add_tab(wb3, "S3.3 PCoA coordinates", "Supplementary Table S3.3 — PCoA coordinates",
        "Sample coordinates (CSS + ConQuR, Bray-Curtis).",
        read.csv("3_stats/pcoa_coordinates.csv"))
# beta stats text -> a small sheet
beta_txt <- readLines("3_stats/beta_summary.txt")
addWorksheet(wb3, "S3.4 Beta stats", gridLines=FALSE)
writeData(wb3, "S3.4 Beta stats", "Supplementary Table S3.4 — Beta diversity statistics")
addStyle(wb3, "S3.4 Beta stats", titl, 1, 1)
writeData(wb3, "S3.4 Beta stats", data.frame(Output=beta_txt), startRow=3)
setColWidths(wb3, "S3.4 Beta stats", cols=1, widths=90)
saveWorkbook(wb3, "5_excel/SupplementaryTable3.xlsx", overwrite=TRUE)

cat("All supplementary Excel files written to 5_excel/\n")
