#!/bin/bash
set -euo pipefail

################################################################################################################################################
# 11.08.2025 CB

# Unicycler v0.5.1 (SPAdes v4.2.0)

# Unicycler SPAdes optimizer with assembly contig clean-up (<200bp)

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate unicycler_env

# Define threads
threads=20

# Minimum contig length (default is 100)
length=200

# Define Illumina paired-end reads ending (with first underscore after sample name)
END1="_forward_paired.fastq.gz"
END2="_reverse_paired.fastq.gz"

# Define input and output folders
short_read_folder="INPUT_short_reads"
output_folder="Unicycler_assembly"
mkdir -p "$output_folder"

################################################################################################################################################
# Don't touch below!
################################################################################################################################################

# Main
for file_path in "$short_read_folder"/*"$END1"; do
   # Check if file is there
   [[ -e "$file_path" ]] || continue
   # Generate names
   sample_name=$(basename "$file_path")
   sample_name="${sample_name%$END1}"
   # Generate read names
   read1="$short_read_folder/${sample_name}${END1}"
   read2="$short_read_folder/${sample_name}${END2}"
   # If read pairs exist, then run Unicycler
      if [[ -f "$read1" && "$read2" ]]; then
         # Unicycler								
         unicycler --threads "$threads" --keep 1 -1 "$read1" -2 "$read2" --min_fasta_length "$length" -o "$output_folder/$sample_name"
         # rename assembly
         mv "$output_folder/$sample_name/assembly.fasta" "$output_folder/$sample_name/${sample_name}_draft_assembly.fasta"
      else
         # Check paired reads input
         echo "Paired-end reads for ${sample_name} do not match.... Skipping sample!"
      fi
done
