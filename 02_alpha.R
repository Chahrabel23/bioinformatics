# ============================================================================
# 02_alpha.R  —  Alpha diversity on NON-normalized counts (per methods)
# Shannon (SDI) + Observed richness (Sobs). Includes baseline (T0) check.
# ============================================================================
cfg <- readRDS("~/desktop/analysis_repeat_16s/.ZmL_config.rds")
list2env(cfg, envir = environment()); setwd(PROJECT_DIR)

library(phyloseq); library(tidyverse); library(ggplot2)

ps  <- readRDS("2_phyloseq/ps_master.rds")
ps  <- subset_samples(ps, Sample_Type == "Larvae")
ps  <- prune_taxa(taxa_sums(ps) > 0, ps)

sd_ <- data.frame(sample_data(ps))
sd_$Diet      <- factor(sd_$Diet, levels = c("Control","Experimental"))
sd_$Timepoint <- factor(sd_$Timepoint, levels = TIMEPOINTS)
sd_$Run       <- factor(sd_$Run)

# ---- Alpha on NON-normalized counts ----
alpha <- estimate_richness(ps, measures = c("Observed","Shannon"))
alpha$SampleID  <- sample_names(ps)
alpha$Diet      <- sd_$Diet
alpha$Run       <- sd_$Run
alpha$Timepoint <- sd_$Timepoint
alpha <- alpha %>% rename(Sobs = Observed, SDI = Shannon)
stopifnot(nrow(alpha) == nsamples(ps))
write.csv(alpha, "3_stats/alpha_diversity.csv", row.names = FALSE)

# ---- Overall Diet effect (Kruskal-Wallis) ----
kw_sobs <- kruskal.test(Sobs ~ Diet, data = alpha)
kw_sdi  <- kruskal.test(SDI  ~ Diet, data = alpha)

# ---- Baseline comparability at T0 (before any inoculation) ----
t0 <- alpha %>% filter(Timepoint == "T0")
w_sobs_t0 <- wilcox.test(Sobs ~ Diet, data = t0)
w_sdi_t0  <- wilcox.test(SDI  ~ Diet, data = t0)

# ---- Per-timepoint Wilcoxon (BH) ----
by_tp <- alpha %>% group_by(Timepoint) %>%
  summarise(p_Sobs = tryCatch(wilcox.test(Sobs~Diet)$p.value, error=function(e) NA),
            p_SDI  = tryCatch(wilcox.test(SDI ~Diet)$p.value, error=function(e) NA),
            .groups="drop") %>%
  mutate(p_Sobs_BH = p.adjust(p_Sobs,"BH"), p_SDI_BH = p.adjust(p_SDI,"BH"))
write.csv(by_tp, "3_stats/alpha_by_timepoint.csv", row.names = FALSE)

# ---- Save a clean stats summary ----
sink("3_stats/alpha_summary.txt")
cat("ALPHA DIVERSITY (non-normalized counts)\n\n")
cat(sprintf("Observed richness, Diet: H = %.3f, p = %.4g\n", kw_sobs$statistic, kw_sobs$p.value))
cat(sprintf("Shannon (SDI),   Diet: H = %.3f, p = %.4g\n\n", kw_sdi$statistic,  kw_sdi$p.value))
cat("BASELINE (T0) comparability:\n")
cat(sprintf("  Observed: W = %g, p = %.3f\n", w_sobs_t0$statistic, w_sobs_t0$p.value))
cat(sprintf("  Shannon : W = %g, p = %.3f\n", w_sdi_t0$statistic,  w_sdi_t0$p.value))
sink()
cat("Alpha stats written. Observed p =", signif(kw_sobs$p.value,3),
    "| T0 Observed p =", signif(w_sobs_t0$p.value,3), "\n")

# ---- Plot: mean +/- SE (NOT SD) ----
summ <- alpha %>%
  pivot_longer(c(Sobs,SDI), names_to="Metric", values_to="Value") %>%
  mutate(Metric = recode(Metric, Sobs="Observed ASVs", SDI="Shannon Index (H')")) %>%
  group_by(Metric, Diet, Timepoint) %>%
  summarise(Mean=mean(Value), SE=sd(Value)/sqrt(n()), n=n(), .groups="drop")

p_alpha <- ggplot(summ, aes(Timepoint, Mean, colour=Diet, group=Diet)) +
  geom_line(linewidth=1) + geom_point(size=2) +
  geom_errorbar(aes(ymin=Mean-SE, ymax=Mean+SE), width=0.2) +
  facet_wrap(~Metric, scales="free_y") +
  scale_colour_manual(values=DIET_COLS) +
  labs(x="Timepoint", y="Value (mean \u00b1 SE)", colour="Diet") +
  theme_bw(base_size=12) +
  theme(panel.grid.minor=element_blank(),
        axis.text.x=element_text(angle=45, hjust=1))
ggsave("4_figures/Fig_alpha_diversity.png", p_alpha, width=11, height=5, dpi=300)
ggsave("4_figures/Fig_alpha_diversity.svg", p_alpha, width=11, height=5)
cat("Saved alpha figure.\n")
