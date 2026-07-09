#!/bin/bash
set -euo pipefail

################################################################################################################################################
# 04.08.2025 CB

# Prokka v1.14.6

# Script to annotate assemblies with Prokka

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate prokka_env

# Define
DATA="INPUT"
GENUS="Pseudomonas"
THR=16

################################################################################################################################################
# Don't touch below!
################################################################################################################################################

# Main
for file_path in "$DATA"/*.{fa,fna,fasta}; do
    # Check if input files exist
    if [[ -f "$file_path" ]]; then
        # Greate basename
        filename=$(basename -- "$file_path")
        basename="${filename%.*}"
        # Define output directory for results
        output_dir="Output_report_${basename}"
        # Run Prokka
        echo "Analyzing $basename .."
	prokka --cpus "$THR" --outdir "$output_dir" --genus "$GENUS" --usegenus --prefix "$baseName" "$file_path"
    fi
done
