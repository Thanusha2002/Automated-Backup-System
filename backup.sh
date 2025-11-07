#!/bin/bash
set -euo pipefail
 
CONFIG_FILE="./backup.config"
LOCK_FILE="/tmp/backup.lock"
 
# --- load config ---
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  echo "Error: $CONFIG_FILE not found"; exit 1
fi
 
mkdir -p "$BACKUP_DESTINATION"
touch "$LOG_FILE"
 
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
 
# Lock
if [ -f "$LOCK_FILE" ]; then
  log "ERROR: locking file exists — another run in progress"; exit 1
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"
# --- Argument Parsing ---
DRY_RUN=false
LIST_MODE=false
RESTORE_MODE=false
 
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --list) LIST_MODE=true; shift ;;
    --restore) RESTORE_MODE=true; BACKUP_FILE="$2"; shift 2 ;;
    --to) RESTORE_TO="$2"; shift 2 ;;
    *) SOURCE_DIR="$1"; shift ;;
  esac
done
# --- Validation ---
if [ "${LIST_MODE:-false}" = true ]; then
  ls -lh "$BACKUP_DESTINATION"/backup-*.tar.gz 2>/dev/null || echo "No backups found."
  exit 0
fi
 
if [ "${RESTORE_MODE:-false}" = true ]; then
  mkdir -p "$RESTORE_TO"
  tar -xzf "$BACKUP_DESTINATION/$BACKUP_FILE" -C "$RESTORE_TO"
  log "SUCCESS: Restored $BACKUP_FILE -> $RESTORE_TO"
  exit 0
fi
 
if [ -z "${SOURCE_DIR:-}" ]; then
  echo "Usage: $0 [--dry-run] <source_dir>  or --list or --restore <file> --to <dir>"
  exit 1
fi
 
if [ ! -d "$SOURCE_DIR" ]; then
  log "ERROR: Source folder not found: $SOURCE_DIR"
  exit 1
fi
 
if [ ! -r "$SOURCE_DIR" ]; then
  log "ERROR: Cannot read source folder: permission denied"
  exit 1
fi
# --- Handle Exclude Patterns ---
IFS=',' read -ra EXCLUDES <<< "$EXCLUDE_PATTERNS"
EXCLUDE_ARGS=()
for e in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(--exclude="$e")
done
# --- Create the Backup ---
TIMESTAMP=$(date +%Y-%m-%d-%H%M)
BACKUP_NAME="backup-$TIMESTAMP.tar.gz"
BACKUP_PATH="$BACKUP_DESTINATION/$BACKUP_NAME"
 
if [ "$DRY_RUN" = true ]; then
  log "DRY RUN: Would create tarball $BACKUP_PATH"
else
  log "INFO: Creating backup $BACKUP_NAME"
  tar -czf "$BACKUP_PATH" "${EXCLUDE_ARGS[@]}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
  log "SUCCESS: Created backup $BACKUP_PATH"
fi
# --- Create and Verify Checksum ---
CHECKSUM_FILE="$BACKUP_PATH.sha256"
 
if [ "$DRY_RUN" = true ]; then
  log "DRY RUN: Would create checksum $CHECKSUM_FILE"
else
  sha256sum "$BACKUP_PATH" > "$CHECKSUM_FILE"
  log "INFO: Created checksum file $CHECKSUM_FILE"
 
  if sha256sum -c "$CHECKSUM_FILE" >/dev/null 2>&1; then
    log "SUCCESS: Checksum verified"
  else
    log "ERROR: Checksum verification failed"
  fi
fi
 
# parse options (dry-run, list, restore) ... (expand later)
 
# main flow:
# 1. validate source
# 2. build exclude args
# 3. create backup tar.gz
# 4. checksum (sha256)
# 5. verify checksum
# 6. test extract a file
# 7. rotate/delete old backups (daily/weekly/monthly)
# 8. clean up & exit