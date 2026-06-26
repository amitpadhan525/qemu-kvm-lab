#!/usr/bin/env bash
set -euo pipefail

# Start a persistent SWTPM instance for the Windows 11 VM.

TPM_DIR="$HOME/VMs/win11/tpm"
SOCKET_PATH="$TPM_DIR/swtpm-sock"
LOG_FILE="$TPM_DIR/swtpm.log"

main() {
  mkdir -p "$TPM_DIR"

  if pgrep -x swtpm >/dev/null 2>&1; then
    echo "swtpm is already running."
    exit 0
  fi

  swtpm socket \
    --tpmstate dir="$TPM_DIR" \
    --ctrl type=unixio,path="$SOCKET_PATH" \
    --tpm2 \
    --daemon \
    --log file="$LOG_FILE"

  echo "swtpm started at $SOCKET_PATH"
}

main "$@"
