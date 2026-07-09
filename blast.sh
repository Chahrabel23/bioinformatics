#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB  06.08.2025

# BLAST v2.16.0

# BLAST using a custom database 

# IMPORTANT -- Your first need to create a custom BLAST database!
# 	To create a database, for example --> $ makeblastdb -in sequences.fasta -dbtype nucl -out plsdb_local

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate blast_env

# Define input and output folders
INPUT_DIR="INPUT"
OUTPUT_DIR="BLAST_reports"
mkdir -p "$OUTPUT_DIR"

# Database to perform BLAST (see note above how to create a BLAST database)
DB="/home/labuser/WGS/Databases/plsdb_local/plsdb_local" # Plasmid database

################################################################################################################################################
# Don't touch below!
################################################################################################################################################

# Main
for fasta_file in "$INPUT_DIR"/*.{fasta,fna,fa}; do
    # Check if assembly file is there
    if [[ -f "$fasta_file" ]]; then
        # Get basename
        base_name=$(basename "$fasta_file")
        base_name="${base_name%.*}"
        # Define output file with path
        output_file="$OUTPUT_DIR/${base_name}_blast.txt"
        # Run BLAST (define parameters based on whatever you are doing; here is set to megablast and to show a max of 10 top hits
        echo "Performing BLAST on $fasta_file"
        blastn -task megablast \
            -query "$fasta_file" \
            -db "$DB" \
            -out "$output_file" \
            -outfmt "7 qseqid sseqid pident length mismatch gapopen qstart qend sstart send slen evalue bitscore qlen" \
            -max_target_seqs 10
    fi
done
echo "BLAST completed!"
