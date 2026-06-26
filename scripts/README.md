# QEMU/KVM Cybersecurity Lab Scripts

This directory contains helper scripts for setting up the networking bridge, creating the Windows 11 VM storage layout, and starting the TPM emulator used by the Windows 11 guest.

## Scripts

- `bridge.sh` — creates/attaches the lab bridge and TAP interfaces.
- `create-win11.sh` — creates the Windows 11 VM directory, disk, and supporting files.
- `start-tpm.sh` — starts the SWTPM daemon for Windows 11.
