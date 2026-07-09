#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

################################################################################################################################################
# 11.08.2025 CB

# Full hybrid assembly pipeline (hybrid_assembly_pipeline.sh):
# 1) First runs Unicycler v0.5.1 (unicycler.sh)
# 2) Then it polishes the unicycler asssembly for one round with Polypolish v0.6.0 and Pypolca v0.3.1 (polishing_step.sh)

# EXTREMELY IMPORTANT: 
# 	First check the individual pipeline scripts (Pipeline_scripts/) for variable definitions BEFORE RUNNING!!!!!!!

################################################################################################################################################
# Don't touch below!
################################################################################################################################################

# Generate log file
LOG_FILE="Hybrid_assembly_pipeline_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Define timestamp
timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

start_time=$(date +%s)
echo "Hybrid assembly pipeline started at: $(timestamp)"

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

run_script "./Pipeline_scripts/unicycler_step.sh"
run_script "./Pipeline_scripts/polishing_step.sh"

end_time=$(date +%s)
elapsed=$(( end_time - start_time ))

echo "Hybrid assembly pipeline finished at: $(timestamp)"
echo "Total time: ${elapsed} seconds"
echo "Full log saved to: $LOG_FILE"

