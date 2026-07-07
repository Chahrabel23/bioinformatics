#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 05.08.2025

# Resfinder v4.7.2

# See manual here --> https://bitbucket.org/genomicepidemiology/resfinder/src/master/
# This is set to default website options: 60% min length (-l 0.6) and 90% ID (-t 0.9)

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate resfinder_env

# Input DATA [FASTA file; draft (Illumina) or complete assembly (Long read or hybrid), including MAGs]
DATA="INPUT"

# Parameters
COV="0.6" # % coverage (-l)
ID="0.9" # % identity (-t)

# Define DB variables
export CGE_RESFINDER_RESGENE_DB="/home/labuser/WGS/Databases/CGE_dbs/resfinder_db"
export CGE_RESFINDER_RESPOINT_DB="/home/labuser/WGS/Databases/CGE_dbs/pointfinder_db"
export CGE_DISINFINDER_DB="/home/labuser/WGS/Databases/CGE_dbs/disinfinder_db"

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
        output_dir="Resfinder_report_${basename}"
        mkdir -p "$output_dir"
        # Run resfinder
        echo "Analyzing $basename .."
        python -m resfinder -o "$output_dir" -l "$COV" -t "$ID" --acquired -ifa "$file_path"
        # Rename output files and append the sample name (basename)
        for original_file in "$output_dir"/*.{fsa,txt}; do
            if [[ -f "$original_file" ]]; then
                filename=$(basename -- "$original_file")
                renamed_file="${output_dir}/${basename}_${filename}"
                mv "$original_file" "$renamed_file"
            fi
        done
    fi
done
echo "Finished analyzing all samples -- BYE BYE!"
