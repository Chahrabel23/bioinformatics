#!/bin/bash
set -euo pipefail

################################################################################################################################################
# ECM 14.08.2025

# Snippy v4.6.0 (gubbins v3.4, snp-sites v2.5.1, snp-dists v0.8.2, iqtree v3.0.1)

# Manual: https://github.com/tseemann/snippy

# This Snippy script calculates the core-genome from either the output of the contig or the read alignment.

# IMPORTANT:
# Make sure there is only one alignment folder present: Snippy_reads_output/ OR Snippy_contigs_output 

# EXTREMELY IMPORTANT: If it fails during Gubbins phylogenetic tree construction, go to line #71 and uncomment it, then comment line #70  

# NOTES:
# To calculate core genome alignment see: core.txt
# To calculate number of recombination sites removed see: core.tab SNPs total minus SNPs in clean.core.aln
# Use --mask (include a BED file) to exclude SNVs from regions in the reference genome: --mask Mask/*.bed

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate snippy_env

# Define input and output folders
input_reference_folder="Input_reference"
output_folder="Snippy_core-genome_output"
mkdir -p "$output_folder"

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Functions to keep track of info and errors
log() { echo -e "[INFO] $*"; }
err() { echo -e "[ERROR] $*" >&2; exit 1; }

# Get reference sequence name and location 
ref_file=$(find "$input_reference_folder" -maxdepth 1 -type f \( -name "*.fa" -o -name "*.fna" -o -name "*.fasta" \) | head -n 1)

# Detect the Snippy output folder
if [ -d "Snippy_reads_output" ] && [ -d "Snippy_contigs_output" ]; then
    err "Both Snippy_reads_output and Snippy_contigs_output exist. Please keep only one."
elif [ -d "Snippy_reads_output" ]; then
    snippy_parent="Snippy_reads_output"
elif [ -d "Snippy_contigs_output" ]; then
    snippy_parent="Snippy_contigs_output"
else
    err "No Snippy output folder found."
fi
log "Using Snippy parent folder: $snippy_parent"

# Get the sub-directories inside $snippy_parent
mapfile -t snippy_dirs < <(find "$snippy_parent" -mindepth 1 -maxdepth 1 -type d | sort)
[ ${#snippy_dirs[@]} -gt 0 ] || err "No sample folders found inside $snippy_parent."
log "Found ${#snippy_dirs[@]} Snippy sample folders."

# Snippy-core
log "Running snippy-core..."
    snippy-core -prefix "$output_folder/core" "${snippy_dirs[@]}" --ref "$ref_file"

# Clean core-genome alignment
full_aln="$output_folder/core.full.aln"
[ -f "$full_aln" ] || err "Missing snippy-core output: $full_aln"
log "Cleaning alignment..."
snippy-clean_full_aln "$full_aln" > "$output_folder/clean.full.aln"

# Gubbins
log "Running Gubbins..."
run_gubbins.py -p "$output_folder/gubbins" "$output_folder/clean.full.aln"
#run_gubbins.py --tree-builder fasttree -p "$output_folder/gubbins" "$output_folder/clean.full.aln"

# SNP-sites
filtered_sites="$output_folder/gubbins.filtered_polymorphic_sites.fasta"
[ -f "$filtered_sites" ] || err "Missing Gubbins output: $filtered_sites"
log "Extracting clean core alignment..."
snp-sites -c "$filtered_sites" > "$output_folder/clean.core.aln"

# SNP-dists
log "Calculating SNP distance matrix..."
snp-dists -b -c "$output_folder/clean.core.aln" > "$output_folder/SNP_Distance_Matrix.csv"

# IQ-TREE
log "Running IQ-TREE..."
iqtree -s "$output_folder/clean.core.aln" -m GTR+ASC -bb 1000 -alrt 1000

log "Snippy core-genome alignment and phylogenetic inference pipeline completed successfully!"
