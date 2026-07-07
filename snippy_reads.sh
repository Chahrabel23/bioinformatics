#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 14.08.2025

# Snippy v4.6.0

# Manual: https://github.com/tseemann/snippy

# This Snippy script takes paired-end illumina reads as input (Input_reads/) and maps them to a reference genome sequence (i.e., complete 
# and circular assembly).

# IMPORTANT: Make sure the suffix of the reference sequence end in either *.fa, *.fna, or *.fasta 

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate snippy_env

# Define input and output folders
input_reads_folder="Input_reads"
input_reference_folder="Input_reference"
output_folder="Snippy_reads_output"
mkdir -p "$output_folder"

# Illumina paired-end reads suffixes (IMPORTANT: make sure this is correct)
END1="_forward_paired.fastq.gz"
END2="_reverse_paired.fastq.gz"

# Set CPU threads
threads=20

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Get reference sequence name and location 
ref_file=$(find "$input_reference_folder" -maxdepth 1 -type f \( -name "*.fa" -o -name "*.fna" -o -name "*.fasta" \) | head -n 1)

# Main
for file_path in "$input_reads_folder"/*"$END1"; do
   # Check if file is there
   [[ -e "$file_path" ]] || continue
   # Generate names
   sample_name=$(basename "$file_path")
   sample_name="${sample_name%$END1}"
   # Generate read names
   read1="$input_reads_folder/${sample_name}${END1}"
   read2="$input_reads_folder/${sample_name}${END2}"
   # If read pairs exist, then run Unicycler
      if [[ -f "$read1" && "$read2" ]]; then
         # Run snippy								
         snippy --cpus "$threads" --outdir "$output_folder/$sample_name" --ref "$ref_file" --R1 "$read1" --R2 "$read2"
      else
         # Check paired reads input
         echo "Paired-end reads for ${sample_name} do not match.... Skipping sample!"
      fi
done
