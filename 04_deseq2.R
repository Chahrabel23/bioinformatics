# ============================================================================
# 04_deseq2.R  —  Differential abundance, DESeq2, batch-adjusted (~ Run + Diet)
# On NON-normalized counts (DESeq2 does its own internal normalization).
# ============================================================================
cfg <- readRDS("~/desktop/analysis_repeat_16s/.ZmL_config.rds")
list2env(cfg, envir = environment()); setwd(PROJECT_DIR)

library(phyloseq); library(DESeq2); library(tidyverse)

ps <- readRDS("2_phyloseq/ps_master.rds")
ps <- subset_samples(ps, Sample_Type == "Larvae")
ps <- prune_taxa(taxa_sums(ps) > 0, ps)
ps_genus <- tax_glom(ps, taxrank = "Genus", NArm = FALSE)

sample_data(ps_genus)$Diet <- factor(sample_data(ps_genus)$Diet,
                                     levels = c("Control","Experimental"))
sample_data(ps_genus)$Run  <- factor(sample_data(ps_genus)$Run)

# ---- DESeq2, batch (Run) adjusted ----
dds <- phyloseq_to_deseq2(ps_genus, ~ Run + Diet)
dds <- estimateSizeFactors(dds, type = "poscounts")   # handles zeros
dds <- DESeq(dds, test = "Wald", fitType = "parametric")

res <- results(dds, contrast = c("Diet","Experimental","Control"), alpha = 0.05)
tax <- as.data.frame(tax_table(ps_genus)) %>% rownames_to_column("ASV")
res_df <- as.data.frame(res) %>% rownames_to_column("ASV") %>%
  left_join(tax, by = "ASV") %>% filter(!is.na(padj)) %>% arrange(padj)
write.csv(res_df, "3_stats/deseq2_experimental_vs_control.csv", row.names = FALSE)

sig <- res_df %>% filter(padj < 0.05)
sink("3_stats/deseq2_summary.txt")
cat("DESeq2 differential abundance (~ Run + Diet)\n\n")
cat("Significant genera (padj<0.05):", nrow(sig), "\n")
cat("  Enriched in Experimental:", sum(sig$log2FoldChange > 0), "\n")
cat("  Enriched in Control     :", sum(sig$log2FoldChange < 0), "\n\n")
cat("Top enriched in Experimental:\n")
print(sig %>% filter(log2FoldChange>0) %>% arrange(desc(log2FoldChange)) %>%
        select(Genus, log2FoldChange, padj) %>% head(15))
sink()
cat("DESeq2 done:", nrow(sig), "significant genera\n")
