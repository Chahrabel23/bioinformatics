#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 05.08.2025

# BUSCO v6.0.0 

# Script to determine number of complete and incomplete marker genes (BUSCO)
# Use autolineage-prok or --lineage_dataset (bacteria_odb10) to force a specific one (modify script below)
# See https://busco.ezlab.org/busco_userguide.html

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate busco_env

# Input folder and threads
DATA="INPUT"
THR="16"
DB_PATH="/home/labuser/WGS/Databases/busco_db/busco_downloads"

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
        # Define output directory for results
        output_dir="Output_report_${basename}"
        # Run BUSCO
        echo "Analyzing $basename .."
	busco -i "$file_path" -o "$output_dir" -m genome --download_path "$DB_PATH" --auto-lineage-prok -c "$THR"
    fi
done
