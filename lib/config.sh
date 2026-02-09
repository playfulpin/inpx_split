#!/usr/bin/env bash
###############################################################################
#  Project: InpxSolutions
#  File   : config.sh
#  Author : mp
#  Date   : 2025-09-19
#
#  Purpose: Define and preserve the project directory structure.
#           This script should be sourced by all project scripts.
###############################################################################

# -----------------------------------------------------------------------------
# Project root (resolve symbolic link ~/DEV/InpxSolutions if possible)
# -----------------------------------------------------------------------------
if command -v realpath >/dev/null 2>&1; then
    PROJECT_ROOT="$(realpath "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)")"
else
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# -----------------------------------------------------------------------------
# Core folders
# -----------------------------------------------------------------------------
DIR_BIN="$PROJECT_ROOT/bin"       # Executables, scripts
DIR_LIB="$PROJECT_ROOT/lib"       # Shared functions & config
DIR_DATA="$PROJECT_ROOT/data"     # Raw input files
DIR_OUTPUT="$PROJECT_ROOT/output" # Generated files
DIR_LOG="$PROJECT_ROOT/log"       # Logs

# -----------------------------------------------------------------------------
# Ensure required directories exist
# -----------------------------------------------------------------------------
mkdir -p "$DIR_BIN" "$DIR_LIB" "$DIR_DATA" "$DIR_OUTPUT" "$DIR_LOG"

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
LOG_FILE="$DIR_LOG/$(basename "$0" .sh).log"

log() {
    local ts level msg
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    level="$1"; shift
    msg="$*"
    echo "[$ts][$level] $msg" | tee -a "$LOG_FILE"
}

log_info()  { log "INFO"  "ℹ️  $*"; }
log_warn()  { log "WARN"  "⚠️  $*"; }
log_error() { log "ERROR" "❌ $*"; }

# -----------------------------------------------------------------------------
# Environment exports (so child scripts can use them)
# -----------------------------------------------------------------------------
export PROJECT_ROOT DIR_BIN DIR_LIB DIR_DATA DIR_OUTPUT DIR_LOG LOG_FILE

###############################################################################
# End of config.sh
###############################################################################
