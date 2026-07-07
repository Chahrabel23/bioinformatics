#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 04.08.2025

# AMRfinder v4.0.24 (database version 2025-07-16.1) 

# Manual: https://github.com/ncbi/amr
# Don't forget to regularly update the AMR database (see manual)
# To see list of organisms: $ amrfinder -l
#	Remove "--organism" flag if organism-specific results are not needed.

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate amrfinder_env

# Define
DATA="INPUT"
MIN_ID="0.5"
ORG="Chryseobacterium"

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Main
for file_path in "$DATA"/*.{fa,fna,fasta}; do
    # Check if input files exist
    if [[ -f "$file_path" ]]; then
        # Greate basename
        filename=$(basename -- "$file_path")
        basename="${filename%.*}"
        # Create output directory for results
        output_dir="Output_report_${basename}"
        mkdir -p "$output_dir"
        # Run amrfinder
        echo "Analyzing $basename .."
        amrfinder -n "$file_path" --plus --ident_min "$MIN_ID" --organism "$ORG" > "${output_dir}/AMReport_${basename}.txt"
    fi
done
