# ============================================================================
# 06_composition.R  —  Stacked-bar composition figures (top 30 genera)
# Stool donors + pooled, and larvae per run + merged. Unclassified -> Other.
# ============================================================================
cfg <- readRDS("~/desktop/analysis_repeat_16s/.ZmL_config.rds")
list2env(cfg, envir = environment()); setwd(PROJECT_DIR)

library(phyloseq); library(tidyverse); library(scales); library(patchwork)

ps_all <- readRDS("2_phyloseq/ps_master.rds")

pal <- c("#4E79A7","#F28E2B","#E15759","#76B7B2","#59A14F","#EDC948","#B07AA1",
         "#FF9DA7","#9C755F","#BAB0AC","#1F77B4","#AEC7E8","#FFBB78","#2CA02C",
         "#98DF8A","#D62728","#FF9896","#9467BD","#C5B0D5","#8C564B","#C49C94",
         "#F7B6D2","#DBDB8D","#9EDAE5","#17BECF","#393B79","#637939","#8C6D31",
         "#843C39","#7B4173")

# collapse unclassified into Other, keep top N real genera
top_long <- function(ps_obj, topn=30) {
  ps_obj@refseq <- NULL
  rel <- transform_sample_counts(ps_obj, function(x) x/sum(x))
  m <- psmelt(tax_glom(rel, "Genus", NArm=FALSE)) %>%
    mutate(Genus = ifelse(is.na(Genus), "Other", as.character(Genus))) %>%
    group_by(Sample, Diet, Run, Timepoint, Sample_Type, Genus) %>%
    summarise(Abundance = sum(Abundance), .groups="drop")
  top <- m %>% filter(Genus!="Other") %>% group_by(Genus) %>%
    summarise(mn=mean(Abundance),.groups="drop") %>% slice_max(mn,n=topn) %>% pull(Genus)
  m$Genus <- ifelse(m$Genus %in% top, m$Genus, "Other")
  m <- m %>% group_by(Sample, Diet, Run, Timepoint, Sample_Type, Genus) %>%
    summarise(Abundance=sum(Abundance), .groups="drop")
  m$Genus <- factor(m$Genus, levels=c(sort(top),"Other"))
  m
}
cols_for <- function(m){ g<-levels(m$Genus); setNames(c(pal[seq_len(length(g)-1)],"grey80"), g) }

# ---- Stool composition ----
ps_s <- subset_samples(ps_all, Sample_Type=="Stool")
ps_s <- prune_taxa(taxa_sums(ps_s)>0, ps_s)
ms <- top_long(ps_s); cs <- cols_for(ms)
p_stool <- ggplot(ms, aes(Sample, Abundance, fill=Genus)) +
  geom_bar(stat="identity", width=0.9) +
  scale_fill_manual(values=cs) + scale_y_continuous(labels=percent, expand=c(0,0)) +
  labs(x=NULL, y="Relative abundance (%)", fill="Genus",
       title="Human stool donors and pooled inoculum") +
  theme_bw(base_size=11) +
  theme(axis.text.x=element_text(angle=45,hjust=1,size=8),
        legend.text=element_text(size=7), legend.key.size=unit(0.35,"cm"))
ggsave("4_figures/Fig_stool_composition.png", p_stool, width=12, height=7, dpi=300)
ggsave("4_figures/Fig_stool_composition.svg", p_stool, width=12, height=7)

# ---- Larvae composition per run (aligned T0-T56 axis) ----
ps_l <- subset_samples(ps_all, Sample_Type=="Larvae")
ps_l <- prune_taxa(taxa_sums(ps_l)>0, ps_l)
ml <- top_long(ps_l); cl <- cols_for(ml)
ml$Diet <- factor(ml$Diet, levels=c("Control","Experimental"),
                  labels=c("Control group","Experimental group"))
ml$Timepoint <- factor(ml$Timepoint, levels=TIMEPOINTS)

run_bar <- function(run){
  d <- ml %>% filter(Run==run)
  ggplot(d, aes(Timepoint, Abundance, fill=Genus)) +
    geom_bar(stat="identity", width=0.85) +
    facet_grid(~Diet) + scale_x_discrete(drop=FALSE) +
    scale_fill_manual(values=cl) + scale_y_continuous(labels=percent, expand=c(0,0)) +
    labs(title=paste0(run," — genus composition"), x="Timepoint",
         y="Relative abundance (%)", fill="Genus") +
    theme_bw(base_size=11) +
    theme(axis.text.x=element_text(angle=45,hjust=1,size=8),
          legend.text=element_text(size=7), legend.key.size=unit(0.3,"cm"))
}
for (rn in c("Run 1","Run 2","Run 3")) {
  pr <- run_bar(rn)
  ggsave(sprintf("4_figures/Fig_larvae_%s.png", gsub(" ","",rn)), pr, width=13, height=6, dpi=300)
}

# mean across runs
mean_l <- ml %>% group_by(Diet, Timepoint, Genus) %>%
  summarise(Mean=mean(Abundance), .groups="drop")
p_mean <- ggplot(mean_l, aes(Timepoint, Mean, fill=Genus)) +
  geom_bar(stat="identity", width=0.8) + facet_grid(~Diet) +
  scale_x_discrete(drop=FALSE) + scale_fill_manual(values=cl) +
  scale_y_continuous(labels=percent, expand=c(0,0)) +
  labs(title="Merged runs (mean) — genus composition", x="Timepoint",
       y="Mean relative abundance (%)", fill="Genus") +
  theme_bw(base_size=11) +
  theme(axis.text.x=element_text(angle=45,hjust=1,size=9),
        legend.text=element_text(size=7), legend.key.size=unit(0.3,"cm"))
ggsave("4_figures/Fig_larvae_merged.png", p_mean, width=13, height=6, dpi=300)
ggsave("4_figures/Fig_larvae_merged.svg", p_mean, width=13, height=6)
cat("Composition figures done.\n")
