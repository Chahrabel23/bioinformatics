#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 05.08.2025

# PlasmidFinder v2.1.6

# This is set to the website options: 60% min coverage (-l 0.6) and 50% ID threshold (-t 0.5)

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate plasmidfinder_env

# Input DATA [FASTA file; draft (Illumina) or complete assembly (Long read or hybrid), including MAGs]
DATA="INPUT"

# Parameters
COV="0.6" # % coverage (-l)
ID="0.5" # % identity (-t)

# Define DB variables
plasmidfinder_db="/home/labuser/WGS/Databases/CGE_dbs/plasmidfinder_db"

# Hide stupid python warning...
export PYTHONWARNINGS="ignore"

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
        output_dir="Plasmidfinder_report_${basename}"
        mkdir -p "$output_dir"
        # Run plasmidfinder
        echo "Analysing $basename .."
        plasmidfinder.py -i "$file_path" -o "$output_dir" -p "$plasmidfinder_db" -l "$COV" -t "$ID" -x -q
        # Rename output files and append the sample name (basename)
        for original_file in "$output_dir"/*.{fsa,txt,tsv}; do
            if [[ -f "$original_file" ]]; then
                filename=$(basename -- "$original_file")
                renamed_file="${output_dir}/${basename}_${filename}"
                mv "$original_file" "$renamed_file"
            fi
        done
    fi
done
echo "Finished analyzing all samples -- BYE BYE!"
