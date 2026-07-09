#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 06.08.2025

# QUAST v5.3.0

# Comprehensive genome assembly (draft or complete/hybrid) QC report (including coverage) with QUAST tool.
# NOTE: This script version uses Nanopore reads!

# IMPORTANT -- Assembly name and read names need to match!
# 	For example: 
#	Assembly name: sample1.fna
#	Nanopore read file name: sample1_Filtlong.fastq.gz
#		Define below in line 33 the nanopore file ending!!

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate quast_env

# Define threads
threads="18"

# Define input and output folders
assembly_folder="INPUT_assembly"
read_folder="INPUT_reads"
output_folder="Quast_report"
mkdir -p "$output_folder"

# Nanopore reads ending (include underscore _)
END="_Filtlong.fastq.gz"

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
	# Get nanopore reads
	nano_reads="$read_folder/${sample_name}${END}"
	# If nanopore reads exist then run QUAST
	if [[ -f "$nano_reads" ]]; then
		echo "Running QUAST using nanopore reads on sample: $sample_name with $threads threads.."
		quast -t "$threads" -o "$output_folder/$sample_name" --nanopore "$nano_reads" "$assembly"
		# Append name to output report
		mv "$output_folder/$sample_name/transposed_report.txt" "$output_folder/$sample_name/${sample_name}_transposed_report.txt"
	else 
		# Need else here in case the paired reads don't match the sample name
		echo "Nanopore reads for ${sample_name} do not match ... Skipping sample!"
	fi
done
