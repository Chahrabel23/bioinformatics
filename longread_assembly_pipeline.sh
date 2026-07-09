#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

################################################################################################################################################
# 11.08.2025 CB

# Full hybrid assembly pipeline (longread_assembly_pipeline.sh):
# 1) First runs Flye v2.9.6 (flye_assembly_step.sh)
# 2) Then it polishes the Flye asssembly 4 rounds with Racon v1.5.0 and then one last single round with Medaka v2.1.0 (polishing_step.sh)

# EXTREMELY IMPORTANT: 
# 	First check the individual pipeline scripts (Pipeline_scripts/) for variable definitions BEFORE RUNNING!!!!!!!

################################################################################################################################################
# Don't touch below!
################################################################################################################################################

# Generate log file
LOG_FILE="Long-read_assembly_pipeline_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Define timestamp
timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

start_time=$(date +%s)
echo "Long-read assembly pipeline started at: $(timestamp)"

# Main
run_script() {
    local script="$1"

    if [[ ! -x "$script" ]]; then
        echo "Cannot run: $script" >&2
        exit 1
    fi

    echo "$(timestamp) | Running: $script"
    bash "$script"
    echo "$(timestamp) | Completed: $script"
}

run_script "./Pipeline_scripts/flye_assembly_step.sh"
run_script "./Pipeline_scripts/polishing_step.sh"

end_time=$(date +%s)
elapsed=$(( end_time - start_time ))

echo "Long-read assembly pipeline finished at: $(timestamp)"
echo "Total time: ${elapsed} seconds"
echo "Full log saved to: $LOG_FILE"

