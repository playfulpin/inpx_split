#!/usr/bin/env bash
###############################################################################
# Progress Bar Utility with Spinner and ETA
#
# Provides a visual progress bar for long-running loops.
# Can be sourced into other scripts or run standalone (demo mode).
#
# Features:
#   - Spinner animation
#   - ETA calculation (MM:SS)
#   - Percent completed
#
# Usage (when sourced):
#   progress_bar current_step total_steps [message]
#
# Example:
#   for ((i=1; i<=100; i++)); do
#       sleep 0.1
#       progress_bar "$i" 100 "Processing"
#   done
#
# Notes:
#   - Does NOT define cleanup or traps. Parent script should manage cleanup.
#   - Safe to source into larger projects (e.g. inpx_splitter.sh).
###############################################################################

# -------------------------------
# Global state
# -------------------------------
_START_TIME=0

# Provide no-op debug if parent script didn’t define it
if ! declare -F debug >/dev/null; then
    debug() { :; }
fi

# -------------------------------
# Function: spinner
# Return: rotating character
# -------------------------------
spinner() {
    local frames=('|' '/' '-' '\')  # escape backslash
    local current=$1
    local spinner_idx=$(( current % 4 ))
    echo -n "${frames[spinner_idx]}"
}

# -------------------------------
# Function: eta_time
# Return: ETA in MM:SS format
# -------------------------------
eta_time() {
    local current=$1
    local total=$2
    local now elapsed remaining

    now=$(date +%s)
    elapsed=$(( now - _START_TIME ))
    remaining="--:--"

    if (( current > 0 && current < total )); then
        local rate=$(( elapsed * total / current ))
        local rem=$(( rate - elapsed ))
        remaining=$(printf "%02d:%02d" $(( rem/60 )) $(( rem%60 )))
    elif (( current >= total )); then
        remaining="00:00"
    fi

    echo "$remaining"
}

# -------------------------------
# Function: progress_bar
# Arguments: current_step total_steps [message]
# -------------------------------
progress_bar() {
    local current=$1
    local total=$2
    local message=${3:-Processing}
    local width=50

    (( current > total )) && current=$total

    # Initialize timer
    if (( _START_TIME == 0 )); then
        _START_TIME=$(date +%s)
    fi

    # Bar segments
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    local bar=$(printf "%0.s█" $(seq 1 $filled))
    local spacer=$(printf "%0.s·" $(seq 1 $empty))

    # Percent
    local percent=$(( current * 100 / total ))

    # Spinner
    local spin
    spin=$(spinner "$current")

    # ETA
    local eta
    eta=$(eta_time "$current" "$total")

    # Print (spaces inside "" are essential!)
    printf "\r%s [%s%s] %3d%% | ETA %s %s  " \
           "$message" "$bar" "$spacer" "$percent" "$eta" "$spin"

    # On completion, print full bar + newline
    if (( current >= total )); then
        printf "\r%s [%s] 100%% | ETA 00:00     \n" \
               "$message" "$(printf "%0.s█" $(seq 1 $width))"
        _START_TIME=0
    fi
}

# -------------------------------
# Demo (runs only if executed directly, not sourced)
# -------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    total=30
    for (( i=1; i<=total; i++ )); do
        sleep 0.1   # simulate work
        progress_bar "$i" "$total" "Demo Run"
    done
    echo "✅ Demo finished"
fi
