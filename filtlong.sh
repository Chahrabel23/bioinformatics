#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 06.08.2025

# Filtlong v0.2.1

# Script to preprocess nanopore reads based on length, quality, etc (see https://github.com/rrwick/Filtlong)

# IMPORTANT: Input nanopore data should be after sequencing adaptor removal (i.e., porechop)

# This script will throw away the worst 10% of read bases (based on Phred) until 1 billion bases remain. Reads lower than 1kb will be discarded.

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate filtlong_env

# Nanopore input data ending
END="_Porechop.fastq.gz"

# Filtlong parameters
# Without external reference
# Min read length of 500 bp, discard the worst 5% reads, and remove the worst reads until only 100000 Mbp remain:
mlen="500"
keep="95"
targetbp="1000000000" # for 1 billion bases use 1000000000 (for 500 million use 500000000)

# Define input and ouput directories:
DATA="INPUT_porechop"
output_folder="Filtlong_preprocessed_reads"
mkdir -p "$output_folder"

# Main
for file_path in "$DATA"/*"$END"; do
    # Check if input reads exist
    if [[ -f "$file_path" ]]; then
        # Greate basename
        filename=$(basename -- "$file_path")
        basename="${filename%$END}"
        # Run porechop
        echo "Filtlong is analyzing $basename .."
        filtlong --min_length "$mlen" \
        --keep_percent "$keep" \
        --target_bases "$targetbp" "$file_path" | gzip > "$output_folder/${basename}_Filtlong.fastq.gz"
    fi
done
echo "Finished preprocessing reads with Filtlong -- BYE BYE!"
