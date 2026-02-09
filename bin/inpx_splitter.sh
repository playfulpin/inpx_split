#!/usr/bin/env bash
###############################################################################
# Title       : inpx_splitter.sh
# Description : Split a full INPX file into two separate INPX files:
#                 1) FB2-formatted books
#                 2) USR-formatted books
#               The script also calculates the number of books in each file
#               and updates the corresponding INPX file headers.
#
# Author      : mp
# Date        : 2025-09-13
# Version     : 1.0.0
# Usage       : ./inpx_splitter.sh [options]
#
# Options     :
#   -d, --debug       Enable debug mode (prints extra information)
#   -h, --help        Show this help message
#
# Notes:
#   - Requires: unzip, 7z, awk, fzf, figlet
#   - Input INPX file is chosen interactively with fzf from current directory
#   - Output files will be named automatically based on the input filename,
#     with suffixes `_fb2.inpx` and `_usr.inpx`.
#   - Uses `progress_bar.sh` for progress reporting:
#         source "$SCRIPT_DIR/../bin/progress_bar.sh"
#         source "$SCRIPT_DIR/../lib/config.sh"
#     That script only provides UI helpers (spinner + ETA).
#     All cleanup of temporary files is handled *locally* in this script.
###############################################################################

# -------------------------------
# Global variables
# -------------------------------
DEBUG=0
INPX_DIR="/mnt/x/Flibusta_maintanance/inpx"
START_DIR="$(pwd)"
TMP_ITEMS=()     # temporary files/dirs for cleanup
TMP_DIR=""
INPUT_FILE=""
OUTPUT_FB2=""
OUTPUT_USR=""
BOOK_COUNTER=0

# -------------------------------
# Helper: print help
# -------------------------------
print_help() {
    grep '^#' "$0" | cut -c 3-
    exit 0
}

# -------------------------------
# Helper: debug logging
# -------------------------------
debug() {
    if (( DEBUG == 1 )); then
        echo "[DEBUG] $*" >&2
    fi
}

# -------------------------------
# Select input file with fzf
# -------------------------------
select_input_file() {
    local file
    file=$(find . -maxdepth 1 -type f -name "*.inpx" \
      | fzf --prompt="Choose file using ↑/↓ arrows. Press ENTER to select.") || exit 1
    INPUT_FILE="$file"
    debug "Selected input file: $INPUT_FILE"
}

# -------------------------------
# Build INPX variant (fb2 / usr)
# Args:
#   $1 = variant name ("fb2" or "usr")
#   $2 = keep patterns
# -------------------------------
build_variant() {
    local variant="$1"
    local patterns="$2"
    local fn_variant="${INPUT_FILE/_all_/_${variant}_}"
    local keep_file

    keep_file=$(mktemp)
    TMP_ITEMS+=("$keep_file")

    debug "Building variant: $variant → $fn_variant"

    # Copy full INPX as base
    # use '\cp' to avoid all alias interference.
    \cp -f "$INPUT_FILE" "$fn_variant"

    # Write keep rules
    echo "$patterns" > "$keep_file"

    # Remove everything except keep list
    debug "Cleaning archive for $variant"
    7z d -tzip "$fn_variant" -x@"$keep_file" >/dev/null

    debug "Build complete: $fn_variant"
}

# -------------------------------
# Count books in extracted .inp files
# Args:
#   $1 = variant ("fb2" or "usr")
# -------------------------------
stat_variant() {
    local variant="$1"

    local tmp_file_list
    tmp_file_list=$(mktemp)
    TMP_ITEMS+=("$tmp_file_list")

    local tmp_books_cnt
    tmp_books_cnt=$(mktemp)
    TMP_ITEMS+=("$tmp_books_cnt")

    debug "Listing $variant .inp files"
    ls -1 "${TMP_DIR}/${variant}"*.inp > "$tmp_file_list" 2>/dev/null || true

    if [[ ! -s "$tmp_file_list" ]]; then
        echo "⚠️ No ${variant} .inp files found."
        BOOK_COUNTER=0
        return
    fi

    local file_counter
    file_counter=$(wc -l < "$tmp_file_list")

    debug "Counting $variant books"
    local i=0
    while read -r fn; do
        ((i++))
        wc -l "$fn" >> "$tmp_books_cnt"
        progress_bar "$i" "$file_counter" "Processing ${variant}"
    done < "$tmp_file_list"

    local book_counter
    book_counter=$(awk '{cnt += $1} END {print cnt}' "$tmp_books_cnt")

    debug "${variant} books = ${book_counter}"
    figlet -f future "Process for ${variant} finished"

    BOOK_COUNTER="$book_counter"
}

# -------------------------------
# Update archive header
# Args:
#   $1 = variant ("fb2" or "usr")
#   $2 = number of books
#   $3 = archive filename
# -------------------------------
update_inpx_header() {
    local variant="$1"
    local num="$2"
    local archive_file="$3"
    local inpx_header="collection.info"

    if [[ ! -f "$archive_file" ]]; then
        echo "❌ Error: $archive_file does not exist."
        exit 2
    fi

    debug "Updating header in $archive_file"

    local arch_version
    arch_version=$(unzip -p "$archive_file" version.info)

    local yy=${arch_version:0:4}
    local mm=${arch_version:4:2}
    local dd=${arch_version:6:2}
    local inpx_version="${yy}-${mm}-${dd}"

    cat <<EOF > "$inpx_header"
Flibusta ${variant} local ${inpx_version}
0
Flibusta. A local ${variant} collection. Total: ${num} ${variant} books
http://flibusta.is/

EOF
    
    # Replace inside archive
    7z a -tzip "$archive_file" "$inpx_header" -y >/dev/null

    debug "Header updated for $variant ($num books)"
}

# -------------------------------
# Function: cleanup
# Removes all temporary files registered in TMP_ITEMS
# This is the *only* place where cleanup is performed.
# progress_bar.sh does not handle cleanup.
# -------------------------------
cleanup() {
    echo -e "\nCleaning up temporary files..."
    for f in "${TMP_ITEMS[@]}"; do
        debug "Deleting ${f}"
        [[ -e $f ]] && rm -rf "$f"
    done
}

# Register cleanup on EXIT, INT, TERM
trap cleanup EXIT INT TERM

# -------------------------------
# External utilities
# -------------------------------
# Provides: progress_bar, spinner, ETA functions
# Safe to source (no cleanup/trap definitions inside)
# -----------------------------------------------------------------------------
# Bootstrap project environment
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/config.sh"
source "$SCRIPT_DIR/../bin/progress_bar.sh"

START_DIR="$(pwd)"   # remember where script was started

# -------------------------------
# Parse CLI arguments
# -------------------------------
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--debug) DEBUG=1 ;;
            -h|--help) print_help ;;
            *) echo "Unknown option: $1"; print_help ;;
        esac
        shift
    done
}

# -------------------------------
# Main function
# -------------------------------
main() {
    parse_arguments "$@"

    # Validate working directory
    if [[ -d "$INPX_DIR" ]]; then
        cd "$INPX_DIR" || exit 1
    else 
        echo "❌ Error: folder $INPX_DIR does not exist!"
        exit 1
    fi

    # Select INPX input file
    select_input_file
    local base_name
    base_name=$(basename "$INPUT_FILE")

    TMP_DIR=$(mktemp -d)
    TMP_ITEMS+=("$TMP_DIR")

    OUTPUT_FB2="${base_name/_all_/_fb2_}"
    OUTPUT_USR="${base_name/_all_/_usr_}"

    echo "Splitting $INPUT_FILE into:"
    echo "  FB2 → $OUTPUT_FB2"
    echo "  USR → $OUTPUT_USR"

    # Build variants
    build_variant "fb2" $'*.info\n*fb2-*.inp'
    build_variant "usr" $'*.info\n*usr-*.inp'

    # Extract full archive for counting
    echo "Extracting files from $INPUT_FILE..."
    unzip -q "$INPUT_FILE" -d "$TMP_DIR"

    # Count FB2 books
    echo "Counting FB2 books..."
    stat_variant "fb2"
    local fb2_books="$BOOK_COUNTER"
    update_inpx_header "fb2" "$fb2_books" "$OUTPUT_FB2"

    # Count USR books
    echo "Counting USR books..."
    stat_variant "usr"
    local usr_books="$BOOK_COUNTER"
    update_inpx_header "usr" "$usr_books" "$OUTPUT_USR"

    # Final message
    figlet -f future "All done"
    echo "📖 FB2 books: $fb2_books"
    echo "📖 USR books: $usr_books"
    
    cd "$START_DIR" || exit 1
    log_info "Returned to original folder: $START_DIR"
}

# -------------------------------
# Entry point
# -------------------------------
main "$@"
