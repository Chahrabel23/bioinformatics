#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 05.08.2025

# MLST v2.0.9

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate mlst-cge_env

# Input DATA [FASTA file; draft (Illumina) or complete assembly (Long read or hybrid), including MAGs]
DATA="INPUT"

# Species MLST database (use species folder name in /home/labuser/WGS/Databases/CGE_dbs/mlst_db)
SP="ecoli1"

# Define DB variable
mlst_db="/home/labuser/WGS/Databases/CGE_dbs/mlst_db"

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
        output_dir="MLST_report_${basename}"
        mkdir -p "$output_dir"
        # Run mlst
        echo "Analyzing $basename .."
        mlst.py -i "$file_path" -o "$output_dir" -s "$SP" -p "$mlst_db" -x -q
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
rm -r tmp_MLST/
echo "Finished analyzing all samples -- BYE BYE!"
