#!/bin/bash
set -euo pipefail

################################################################################################################################################
# CB 14.08.2025

# SyRi v1.7.1

# Manual: https://schneebergerlab.github.io/syri/pipeline.html

# To calculate Synteny and Rearrangements in genomes...

# NOTE: Can only calculate 1 genome vs. 1 reference genome at the time.

################################################################################################################################################

# Initialize Anaconda environmet
source ~/anaconda3/etc/profile.d/conda.sh
conda activate syri_env

# Hide python warning
export PYTHONWARNINGS="ignore"

# Define input and output folders
input_reference_folder="Input_reference"
input_genome_folder="Input_genome"
output_folder="Syri_output"
mkdir -p "$output_folder"

# Functions to keep track of info and errors
log() { echo -e "[INFO] $*"; }
err() { echo -e "[ERROR] $*" >&2; exit 1; }

# Get reference sequence name and location 
ref_file=$(find "$input_reference_folder" -maxdepth 1 -type f \( -name "*.fa" -o -name "*.fna" -o -name "*.fasta" \) | head -n 1)

# Get query genome name and location
gen_file=$(find "$input_genome_folder" -maxdepth 1 -type f \( -name "*.fa" -o -name "*.fna" -o -name "*.fasta" \) | head -n 1)

# Generate genome input file for syri
out="$output_folder/genomes.txt"
echo -e "#file\tname" > "$out"
make_name() {
    basename "$1" | cut -d. -f1
}
echo -e "${ref_file}\t$(make_name "$ref_file")" >> "$out"
echo -e "${gen_file}\t$(make_name "$gen_file")" >> "$out"

################################################################################################################################################
# Do not modify below!
################################################################################################################################################

# Main

# nucmer alignment
log "Running nucmer..."
nucmer --maxmatch "$ref_file" "$gen_file" -p "$output_folder/nucmer-output"

# Remove small and lower quality alignments
nucmer_out="$output_folder/nucmer-output.delta"
[ -f "$nucmer_out" ] || err "Missing nucmer delta output: $nucmer_out"
log "Removing small and lower quality alignments with delta-filter..."
delta-filter -m -i 90 -l 100 "$nucmer_out" > "$output_folder/nucmer-output.filtered.delta"

# Convert alignment information to a .TSV format as required by SyRI
nucmer_delta_filtered_out="$output_folder/nucmer-output.filtered.delta"
[ -f "$nucmer_delta_filtered_out" ] || err "Missing nucmer delta output: $nucmer_delta_filtered_out"
log "Removing small and lower quality alignments with delta-filter..."     
show-coords -THrd "$nucmer_delta_filtered_out" > "$output_folder/nucmer-output.filtered.coords"      

# Run syri
nucmer_delta_filtered_coords_out="$output_folder/nucmer-output.filtered.coords"
[ -f "$nucmer_delta_filtered_coords_out" ] || err "Missing nucmer delta filtered coords output: $nucmer_delta_filtered_coords_out"
log "Running SyRi..."     
syri -c "$nucmer_delta_filtered_coords_out" -d "$nucmer_delta_filtered_out" -r "$ref_file" -q "$gen_file"

# Plot
mv *.{out,log,summary,vcf} "$output_folder"
syri_out="$output_folder/syri.out"
[ -f "$syri_out" ] || err "Missing SyRi output: $syri_out"
genomes="$output_folder/genomes.txt"
[ -f "$genomes" ] || err "Missing genomes input file: $genomes"
log "Plotting SyRi alignment..."     
plotsr --sr "$syri_out" --genomes "$genomes" -o "$output_folder/plotsr_plot.pdf" -S 0.3 -W 7 -H 7 -f 4 -d 600 -b pdf
mv *.log "$output_folder"

# End
[ -f "$output_folder/plotsr_plot.pdf" ] || err "plotsr failed to generate plot!"
log "SyRi pipeline complete -- Bye Bye! \U1F600"
