# ============================================================================
# 05_targets.R  —  Ten target genera: inoculum %, detection, Wilcoxon,
# trajectories, and the humanization score. Targets matched by name (robust).
# ============================================================================
cfg <- readRDS("~/desktop/analysis_repeat_16s/.ZmL_config.rds")
list2env(cfg, envir = environment()); setwd(PROJECT_DIR)

library(phyloseq); library(tidyverse); library(ggplot2); library(rstatix)

ps_all <- readRDS("2_phyloseq/ps_master.rds")

# ---- Define the 10 targets = 10 most abundant genera in the POOLED inoculum ----
ps_pool <- subset_samples(ps_all, Sample_Type == "Stool")   # includes pooled
ps_pool <- prune_taxa(taxa_sums(ps_pool) > 0, ps_pool)
ps_pool_rel <- transform_sample_counts(ps_pool, function(x) x/sum(x))

pool_long <- psmelt(tax_glom(ps_pool_rel, "Genus", NArm = FALSE)) %>%
  mutate(Genus = as.character(Genus)) %>% filter(!is.na(Genus))

# If a 'Pooled' sample exists use it; else use donor mean to rank targets
pooled_ids <- grep("Pooled|pool", sample_names(ps_pool), value = TRUE)
rank_src <- if (length(pooled_ids)>0)
  pool_long %>% filter(Sample %in% pooled_ids) else pool_long
TARGETS <- rank_src %>% group_by(Genus) %>%
  summarise(m = mean(Abundance), .groups="drop") %>%
  arrange(desc(m)) %>% slice_head(n = 10) %>% pull(Genus)
cat("Target genera:\n"); print(TARGETS)

# ---- S2.1 inoculum: donor range + pooled ----
inoc <- pool_long %>% filter(Genus %in% TARGETS) %>%
  left_join(data.frame(sample_data(ps_pool)) %>% rownames_to_column("Sample") %>%
              select(Sample, Sample_Type2 = Sample_Type), by="Sample")
donor_range <- pool_long %>% filter(Genus %in% TARGETS) %>%
  group_by(Genus) %>% summarise(Donor_min = min(Abundance)*100,
                                Donor_max = max(Abundance)*100, .groups="drop")
write.csv(donor_range, "3_stats/S2.1_target_inoculum.csv", row.names = FALSE)

# ---- Larval target trajectories ----
ps_l <- subset_samples(ps_all, Sample_Type == "Larvae")
ps_l <- prune_taxa(taxa_sums(ps_l) > 0, ps_l)
ps_l_rel <- transform_sample_counts(ps_l, function(x) x/sum(x))

lar_long <- psmelt(tax_glom(ps_l_rel, "Genus", NArm = FALSE)) %>%
  mutate(Genus = as.character(Genus)) %>% filter(!is.na(Genus)) %>%
  mutate(Diet = factor(Diet, levels=c("Control","Experimental")),
         Timepoint = factor(Timepoint, levels=TIMEPOINTS))

tgt_long <- lar_long %>% filter(Genus %in% TARGETS)

# detection
detect <- tgt_long %>% group_by(Genus) %>%
  summarise(Detected = ifelse(any(Abundance>0),"Yes","No"),
            N_pos = sum(Abundance>0), Max_pct = round(max(Abundance)*100,4),
            .groups="drop")
write.csv(detect, "3_stats/S2.2_detection.csv", row.names = FALSE)

# Wilcoxon per genus (BH)
wilcox <- tgt_long %>% group_by(Genus) %>%
  wilcox_test(Abundance ~ Diet) %>% adjust_pvalue(method="BH") %>%
  add_significance("p.adj")
write.csv(wilcox, "3_stats/S2.3_wilcoxon.csv", row.names = FALSE)

# trajectories mean +/- SE
traj <- tgt_long %>% group_by(Genus, Timepoint, Diet) %>%
  summarise(Mean=mean(Abundance), SE=sd(Abundance)/sqrt(n()), n=n(), .groups="drop")
write.csv(traj, "3_stats/S2.4_trajectories.csv", row.names = FALSE)

# humanization score = sum of 10 targets per sample
hscore <- tgt_long %>% group_by(Sample, Diet, Run, Timepoint) %>%
  summarise(Humanization = sum(Abundance), .groups="drop")
write.csv(hscore, "3_stats/S2.5_humanization_score.csv", row.names = FALSE)
kw_h <- kruskal.test(Humanization ~ Diet, data = hscore)
cat(sprintf("Humanization score, Diet: H=%.2f p=%.4g\n", kw_h$statistic, kw_h$p.value))

# ---- Figure: target trajectories, one panel per genus ----
traj$Genus <- factor(traj$Genus, levels = TARGETS)
p <- ggplot(traj, aes(Timepoint, Mean*100, colour=Diet, group=Diet)) +
  geom_line(linewidth=0.8) + geom_point(size=1.6) +
  geom_errorbar(aes(ymin=pmax(0,(Mean-SE)*100), ymax=(Mean+SE)*100), width=0.2, alpha=0.6) +
  geom_vline(xintercept=which(TIMEPOINTS=="T28"), linetype="dashed", colour="grey50") +
  facet_wrap(~Genus, scales="free_y", ncol=2) +
  scale_colour_manual(values=DIET_COLS) +
  labs(x="Timepoint", y="Mean relative abundance (%) \u00b1 SE", colour="Diet",
       caption="Dashed line = end of inoculation (T28)") +
  theme_bw(base_size=11) +
  theme(panel.grid.minor=element_blank(), axis.text.x=element_text(angle=45,hjust=1),
        legend.position="bottom", strip.text=element_text(face="italic"))
ggsave("4_figures/Fig_target_trajectories.png", p, width=11, height=14, dpi=300)
ggsave("4_figures/Fig_target_trajectories.svg", p, width=11, height=14)

# ---- Figure: humanization score ----
hs_tp <- hscore %>% group_by(Diet, Timepoint) %>%
  summarise(Mean=mean(Humanization)*100, SE=sd(Humanization)/sqrt(n())*100, .groups="drop")
p2 <- ggplot(hs_tp, aes(Timepoint, Mean, colour=Diet, group=Diet)) +
  geom_line(linewidth=1) + geom_point(size=2) +
  geom_errorbar(aes(ymin=pmax(0,Mean-SE), ymax=Mean+SE), width=0.2) +
  scale_colour_manual(values=DIET_COLS) +
  labs(x="Timepoint", y="Humanization score (%) \u00b1 SE", colour="Diet") +
  theme_bw(base_size=12) + theme(panel.grid.minor=element_blank(),
                                 axis.text.x=element_text(angle=45,hjust=1))
ggsave("4_figures/Fig_humanization_score.png", p2, width=8, height=5, dpi=300)
ggsave("4_figures/Fig_humanization_score.svg", p2, width=8, height=5)

saveRDS(TARGETS, "2_phyloseq/target_genera.rds")
cat("Targets done.\n")
