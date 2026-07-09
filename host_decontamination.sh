#!/bin/zsh
set -euo pipefail

################################################################################################################################################
# CB 19.08.2025

# Script to decontaminate host read from Nanopore sequencing data: it uses minimap2 v2.30 and samtools v1.22.1

# Note: You can use any reference sequence/genome to decontaminate or select nanopore reads. Make sure you place those reference sequences
#       in the reference directory /home/labuser/WGS/Databases/Reference_genomes and that they are correctly defined in this script.
#           For example, ref_fish="$ref_dir/cool_fish_genome.fna" then ref="$ref_fish"

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate decontaminate_env

# CPU threads
threads=20

# Nanopore input data ending (make sure this is correct)
nano_end="_Porechop.fastq.gz"

# Define input and output directories
reads="Input_nanopore_reads"
deco_out="Decontaminated_nanopore_reads"
mkdir -p "$deco_out"

# Reference directory and genones
ref_dir="/home/labuser/WGS/Databases/Reference_genomes"
ref_human="$ref_dir/GCF_000001405.40_GRCh38.p14_genomic.fna"
ref_zmorio="$ref_dir/GCA_027724725.1_ASM2772472v1_genomic.fna"

# Choose a reference genome to map the nanopore reads against (options: "$ref_human" or "$ref_zmorio")
ref="$ref_zmorio"

# Type of read mapping
# Set mappping to "-f" to get unmapped reads (everything excep the host) or "-F" to get mapped reads (the host reads)
mapping="-f"

################################################################################################################################################
# Do not touch below!
################################################################################################################################################

# Main
for file_path in "$reads"/*"$nano_end"; do
   if [[ -f "$file_path" ]]; then
      # Generate basename
      filename=$(basename "$file_path")
      basename="${filename%$nano_end}"
      # Run minimap2
      echo "Decontaminating ${basename} .."
      minimap2 -ax map-ont -y "$ref" "$file_path" -t "$threads" | samtools fastq -@ "$threads" -n "$mapping" 4 - | pigz  > "$deco_out/${basename}_clean.fastq.gz"
   fi
done
