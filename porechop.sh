#!/bin/zsh
set -euo pipefail

################################################################################################################################################
# CB 06.08.2025

# Porechop v0.2.4-4
# NOTE: This version of porechop that contains the latest sequencing barcodes.
# It includes the latest Nanopore adaptors as of February 2024 (v0.2.4-4) 
# More info https://github.com/mdondrup/Porechop

# NOTE: the --discard_middle adaptors flag is used to reduce potential barcode contamination

################################################################################################################################################

# Initialize Python virtual environmet
source /home/labuser/WGS/Python_envs/porechop_mod_env/bin/activate

# Threads
THR="20"

# Nanopore input raw data ending
END=".fastq.gz"

# Define input and output directories:
DATA="INPUT_raw"
output_folder="Porechop_preprocessed_reads"
mkdir -p "$output_folder"

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Main
for file_path in "$DATA"/*"$END"; do
    # Check if input reads exist
    if [[ -f "$file_path" ]]; then
        # Greate basename
        filename=$(basename -- "$file_path")
        basename="${filename%$END}"
        # Run Porechop
        echo "Porechop is doing chop chop chop $basename .."
        porechop -t "$THR" -i "$file_path" -o "$output_folder/${basename}_Porechop.fastq.gz" --discard_middle --format fastq.gz
    fi
done
echo "Finished preprocessing reads with Porechop -- BYE BYE!"
