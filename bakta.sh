#!/bin/bash
set -euo pipefail

################################################################################################################################################
# 04.08.2025 CB

# Bakta v1.11.3 (database version: 2025-02-24)

# Script to annotate assemblies with Bakta
# See https://github.com/oschwengers/bakta?tab=readme-ov-file#examples

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate bakta_env

# Set database variable
export BAKTA_DB=/home/labuser/WGS/Databases/bakta_db

# Input folder and threads
DATA="INPUT"
THR=20

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
        # Run Bakta
        echo "Analyzing $basename .."
	bakta --db "$BAKTA_DB" --verbose --output "$output_dir" --prefix "$basename" --threads "$THR" "$file_path"
    fi
done
