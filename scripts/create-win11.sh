#!/usr/bin/env bash
set -euo pipefail

# Create a Windows 11 VM disk and supporting files for the QEMU/KVM lab.
# This script assumes the ISO files and OVMF/SWTPM support packages are installed.

VM_NAME="win11"
VM_DIR="$HOME/VMs/$VM_NAME"
DISK_SIZE="100G"
WINDOWS_ISO="$HOME/Downloads/ISO/Win11_25H2_English_x64_v2.iso"
VIRTIO_ISO="$HOME/Downloads/ISO/virtio-win-0.1.285.iso"
OVMF_SOURCE="/usr/share/edk2/x64/OVMF_VARS.4m.fd"
OVMF_TARGET="$VM_DIR/OVMF_VARS_SECBOOT.fd"
TPM_DIR="$VM_DIR/tpm"
DISK_PATH="$VM_DIR/$VM_NAME.qcow2"

require_tools() {
  local missing=0
  for tool in qemu-img cp mkdir; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing required tool: $tool" >&2; missing=1; }
  done
  [[ $missing -eq 0 ]]
}

check_iso() {
  local iso="$1"
  if [[ ! -f "$iso" ]]; then
    echo "Missing ISO: $iso" >&2
    exit 1
  fi
}

main() {
  require_tools
  check_iso "$WINDOWS_ISO"
  check_iso "$VIRTIO_ISO"

  mkdir -p "$TPM_DIR"
  if [[ ! -f "$DISK_PATH" ]]; then
    qemu-img create -f qcow2 "$DISK_PATH" "$DISK_SIZE"
  else
    echo "Disk already exists: $DISK_PATH"
  fi

  if [[ -f "$OVMF_SOURCE" ]]; then
    cp -n "$OVMF_SOURCE" "$OVMF_TARGET"
  else
    echo "Warning: OVMF source not found at $OVMF_SOURCE" >&2
  fi

  cat > "$VM_DIR/README.txt" <<EOF
Windows 11 VM directory for the QEMU/KVM lab.

Disk: $DISK_PATH
Windows ISO: $WINDOWS_ISO
VirtIO ISO: $VIRTIO_ISO
EOF

  echo "Windows 11 VM skeleton created in $VM_DIR"
}

main "$@"
