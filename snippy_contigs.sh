#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 14.08.2025

# Snippy v4.6.0

# Manual: https://github.com/tseemann/snippy

# This Snippy script takes genome assemblies as input (Input_contigs/) and converts them into pseudocontigs. Then it maps the contigs to a
# reference genome assembly (i.e., complete and circular genome).

# IMPORTANT: Make sure the suffixes of the reference and genome sequences end in either *.fa, *.fna, or *.fasta 

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate snippy_env

# Define input and output folders
input_contigs_folder="Input_contigs"
input_reference_folder="Input_reference"
output_folder="Snippy_contigs_output"
mkdir -p "$output_folder"

# Set CPU threads
threads=20

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Get reference sequence name and location 
ref_file=$(find "$input_reference_folder" -maxdepth 1 -type f \( -name "*.fa" -o -name "*.fna" -o -name "*.fasta" \) | head -n 1)

# Main
for file_path in "$input_contigs_folder"/*.{fa,fna,fasta}; do
# Check if input sequence is there
   if [[ -f "$file_path" ]]; then  
      # Generate sample name
      filename=$(basename -- "$file_path")
      sample_name="${filename%.*}"
      # Snippy code
      echo "Analyzing $sample_name"
      snippy --cpus "$threads" --outdir "$output_folder/$sample_name" --ref "$ref_file" --ctgs "$file_path"
   fi
done
