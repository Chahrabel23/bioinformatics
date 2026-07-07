#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 05.08.2025

# CheckM v1.2.4

# To asssess completeness and contamination of a genome assembly or a collection of genomes within a bin (after binning)
# This script takes one sample at the time.
# Note: A good quality assembly or bin is: >95% completeness and <5% contamination.

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate checkm_env

# Hide python warning
export PYTHONWARNINGS="ignore"

# Directory with single draft or complete assemblies; OR MAG bins
bin_dir="INPUT"

# Fasta extension (fa, fna, fasta)
EXT="fa"

# Define output directory
checkm_out_dir="Checkm_report"
mkdir -p "$checkm_out_dir"

# Threads
THR="16"

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Main
checkm lineage_wf "$bin_dir" "$checkm_out_dir" -t "$THR" -x "$EXT" -f "$checkm_out_dir/checkm_results.tsv" --tab_table 
