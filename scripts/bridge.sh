#!/usr/bin/env bash
set -euo pipefail

# Configure a Linux bridge and TAP interfaces for the QEMU/KVM lab.
# Adjust interface names if your host uses different TAP devices.

BRIDGE_NAME="br0"
PHYSICAL_IFACE="enp6s0"
TAP_INTERFACES=(tap0 tap1 tap2 tap3)

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Please run this script as root (or with sudo)." >&2
    exit 1
  fi
}

create_bridge() {
  if ! ip link show "$BRIDGE_NAME" &>/dev/null; then
    ip link add name "$BRIDGE_NAME" type bridge
  fi
  ip link set "$BRIDGE_NAME" up
}

attach_physical_iface() {
  if ip link show "$PHYSICAL_IFACE" &>/dev/null; then
    ip link set "$PHYSICAL_IFACE" master "$BRIDGE_NAME"
    ip link set "$PHYSICAL_IFACE" up
  else
    echo "Warning: physical interface '$PHYSICAL_IFACE' not found; skipping." >&2
  fi
}

create_tap_iface() {
  local tap="$1"
  if ! ip link show "$tap" &>/dev/null; then
    ip tuntap add dev "$tap" mode tap user "$SUDO_USER"
  fi
  ip link set "$tap" master "$BRIDGE_NAME"
  ip link set "$tap" up
}

main() {
  require_root
  create_bridge
  attach_physical_iface
  for tap in "${TAP_INTERFACES[@]}"; do
    create_tap_iface "$tap"
  done

  echo "Bridge '$BRIDGE_NAME' is ready."
  bridge link show
}

main "$@"
