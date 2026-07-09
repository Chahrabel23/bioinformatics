#!/bin/bash
set -euo pipefail

################################################################################################################################################
# ECM 06.08.2025

# QUAST v5.3.0

# Comprehensive genome assembly (draft or complete/hybrid) QC report (including coverage) with QUAST tool.

# IMPORTANT -- Assembly name and read names need to match!
# 	For example: 
#	Assembly name: sample1.fna
#	Read names: sample1_forward_paired.fastq.gz, sample1_reverse_paired.fastq.gz
#		NOTE= QUAST will still give a warning about the sample name not containing /1 or /2 -- IGNORE!

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate quast_env

# Define threads
threads="18"

# Define paired-end reads ending (with first underscore after sample name)
END1="_forward_paired.fastq.gz"
END2="_reverse_paired.fastq.gz"

# Define input and output folders
assembly_folder="INPUT_assembly"
read_folder="INPUT_reads"
output_folder="Quast_report"
mkdir -p "$output_folder"

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Main
for assembly in "$assembly_folder"/*.{fasta,fna,fa}; do
	# Check if assembly file is there
	[[ -e "$assembly" ]] || continue
	# Generate sample name
	sample_name=$(basename "$assembly")
	sample_name="${sample_name%.*}"
	# Get read pairs
	read1="$read_folder/${sample_name}${END1}"
	read2="$read_folder/${sample_name}${END2}"
	# If read pairs exist then run QUAST
	if [[ -f "$read1" && -f "$read2" ]]; then
		echo "Running QUAST on sample: $sample_name with $threads threads.."
		quast -t "$threads" -o "$output_folder/$sample_name" --pe1 "$read1" --pe2 "$read2" "$assembly"
		# Append name to output report
		mv "$output_folder/$sample_name/transposed_report.txt" "$output_folder/$sample_name/${sample_name}_transposed_report.txt"
	else 
		# Need else here in case the paired reads don't match the sample name
		echo "Paired-end reads for ${sample_name} do not match OR end in *_R1.fastq.gz or *_R2.fastq.gz ... Skipping sample!"
	fi
done
