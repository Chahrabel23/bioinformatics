#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 06.08.2025

# Trimmomatic v0.39

# Script to preprocess illumina raw reads (remove adapter sequences, etc)

# IMPORTANT:
# TruSeq3-PE-2.fa are the default adapters (good for Novaseq 6000 instrument)
# For SRA data use: custom-all.fa

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate trimmomatic_env

# Threads
THR="20"

# Adapter path
ADAPTERS="/home/labuser/WGS/Databases/Illumina_adapters"

# Adapter file
ADAPTER_FILE="${ADAPTERS}/TruSeq3-PE-2.fa"

# Define input and output directories
READS="INPUT"
output_folder="Trimmed_reads"
mkdir -p "$output_folder"

# Illumina reads endings
FWD_END="_1.fastq.gz"
REV_END="_2.fastq.gz"

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Process each forward read and match
find "$READS" -type f -name "*${FWD_END}" | while read -r r1; do
    # Create basename and match to reverse read path
    base="${r1%$FWD_END}"
    r2="${base}${REV_END}"
    baseName="$(basename "$base")"
    # Define output file paths
    outFp="${output_folder}/${baseName}_forward_paired.fastq"
    outFu="${output_folder}/${baseName}_forward_unpaired.fastq"
    outRp="${output_folder}/${baseName}_reverse_paired.fastq"
    outRu="${output_folder}/${baseName}_reverse_unpaired.fastq"
    # Run trimmomatic
    trimmomatic PE -threads "$THR" -phred33 \
        "$r1" "$r2" \
        "$outFp" "$outFu" \
        "$outRp" "$outRu" \
        ILLUMINACLIP:"$ADAPTER_FILE":2:30:10 \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done
echo "Finished trimming all samples!"

# Delete unpaired reads
rm -f "${output_folder}"/*_unpaired.fastq

# Compress paired fastq files
echo "Compressing reads..."
find "$output_folder" -type f -name "*.fastq" | xargs -P "$THR" -n 1 pigz
echo "FINISHED - BYE BYE!"
