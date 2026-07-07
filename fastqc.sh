#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 06.08.2025

# fastqc v0.12.1

# Generates QC stats of Illumina reads
# Note: Place all reads in INPUT/ directory (they don't need to match: one report per file is generated)

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate fastqc_env

# Define input directory and ending of illumina reads
READS="INPUT"
ENDING=".fastq.gz"
output_folder="FASTQC_report"
mkdir -p "$output_folder"

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Main
fastqc "$READS"/*"$ENDING" -o "$output_folder"

