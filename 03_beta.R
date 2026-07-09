# ============================================================================
# 03_beta.R  —  Beta diversity: CSS normalization + ConQuR batch correction
# Then Bray-Curtis -> PCoA -> PERMANOVA (marginal) + betadisper
# ============================================================================
cfg <- readRDS("~/desktop/analysis_repeat_16s/.ZmL_config.rds")
list2env(cfg, envir = environment()); setwd(PROJECT_DIR)

library(phyloseq); library(tidyverse); library(vegan)
library(metagenomeSeq); library(ConQuR); library(doParallel); library(ggplot2)

ps <- readRDS("2_phyloseq/ps_master.rds")
ps <- subset_samples(ps, Sample_Type == "Larvae")
ps <- prune_taxa(taxa_sums(ps) > 0, ps)

ps_genus <- tax_glom(ps, taxrank = "Genus", NArm = FALSE)

meta <- data.frame(sample_data(ps_genus))
meta$Diet      <- factor(meta$Diet, levels = c("Control","Experimental"))
meta$Run       <- factor(meta$Run)
meta$Timepoint <- factor(meta$Timepoint, levels = TIMEPOINTS)

# ---- 1. CSS normalization (metagenomeSeq) ----
otu <- as(otu_table(ps_genus), "matrix")
if (!taxa_are_rows(ps_genus)) otu <- t(otu)     # taxa x samples
mr  <- newMRexperiment(otu)
mr  <- cumNorm(mr, p = cumNormStatFast(mr))
css <- t(MRcounts(mr, norm = TRUE, log = FALSE)) # samples x taxa

# ---- 2. ConQuR batch correction (batch = Run) ----
set.seed(SEED); registerDoParallel(cores = 2)
css_bc <- ConQuR(tax_tab   = as.data.frame(css),
                 batchid   = meta$Run,
                 covariates = meta[, c("Diet","Timepoint")],
                 batch_ref = levels(meta$Run)[1],
                 logistic_lasso = FALSE, quantile_type = "lasso",
                 interplt = FALSE)
stopImplicitCluster()
css_bc <- as.matrix(css_bc)

# ---- 3. Bray-Curtis + PCoA ----
bc  <- vegdist(css_bc, method = "bray")
pc  <- cmdscale(bc, k = 3, eig = TRUE)
eig <- round(100 * pc$eig / sum(pc$eig[pc$eig > 0]), 1)
pcoa_df <- data.frame(SampleID=rownames(css_bc),
                      PC1=pc$points[,1], PC2=pc$points[,2],
                      Diet=meta$Diet, Run=meta$Run, Timepoint=meta$Timepoint)
write.csv(pcoa_df, "3_stats/pcoa_coordinates.csv", row.names = FALSE)

# ---- 4. PERMANOVA (marginal) + betadisper ----
set.seed(SEED); perm_diet   <- adonis2(bc ~ Diet, data = meta, permutations = 999)
set.seed(SEED); perm_margin <- adonis2(bc ~ Run + Diet, data = meta,
                                       permutations = 999, by = "margin")
disp <- betadisper(bc, meta$Diet); disp_test <- permutest(disp, permutations = 999)

sink("3_stats/beta_summary.txt")
cat("BETA DIVERSITY (CSS + ConQuR, Bray-Curtis)\n\n")
cat("PCoA variance explained: PC1", eig[1], "% PC2", eig[2], "%\n\n")
cat("=== PERMANOVA ~ Diet ===\n"); print(perm_diet)
cat("\n=== PERMANOVA ~ Run + Diet (marginal) ===\n"); print(perm_margin)
cat("\n=== BETADISPER ~ Diet ===\n"); print(disp_test)
sink()
cat(sprintf("Diet R2 = %.3f (p=%.3f) | betadisper p = %.3f\n",
            perm_diet$R2[1], perm_diet$`Pr(>F)`[1], disp_test$tab$`Pr(>F)`[1]))

# ---- 5. PCoA plot ----
p <- ggplot(pcoa_df, aes(PC1, PC2, colour = Diet)) +
  geom_point(size=2, alpha=0.85) +
  stat_ellipse(aes(group=Diet), type="t", level=0.95, linetype="dashed", linewidth=0.8) +
  scale_colour_manual(values = DIET_COLS) +
  labs(x=sprintf("PC1 (%.1f%%)", eig[1]), y=sprintf("PC2 (%.1f%%)", eig[2]),
       title="PCoA — Bray-Curtis (CSS + ConQuR)", colour="Diet") +
  theme_bw(base_size=12) + theme(panel.grid.minor=element_blank())
ggsave("4_figures/Fig_PCoA.png", p, width=7, height=6, dpi=300)
ggsave("4_figures/Fig_PCoA.svg", p, width=7, height=6)

saveRDS(list(bc=bc, css_bc=css_bc, meta=meta), "2_phyloseq/beta_objects.rds")
cat("Beta done.\n")
