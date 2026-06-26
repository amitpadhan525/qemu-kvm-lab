# Troubleshooting QEMU/KVM Lab Issues (The Survival Guide)

When you are playing around with virtualization, custom network bridges, and emulated TPM chips on Arch Linux, things *will* break. QEMU will throw a cryptic error and refuse to start, or your VM will boot up but won't connect to anything.

Honestly, troubleshooting is just a fancy word for finding out why your code or VM is crying, and fixing it without crying yourself. 

Instead of panic-reinstalling your whole OS or stackoverflowing blindly, this guide covers how to read logs, find the root cause, and fix the most common errors in our lab setup.

---

## What we're covering:

* [What actually is troubleshooting?](#what-actually-is-troubleshooting)
* [Why do we need to learn this?](#why-do-we-need-to-learn-this)
* [The Career Cheat Code (Why this is the best skill to learn)](#the-career-cheat-code-why-this-is-the-best-skill-to-learn)
* [Most common errors in our lab & How to fix them](#most-common-errors-in-our-lab--how-to-fix-them)
  * [1. The KVM kernel module / permission error](#1-the-kvm-kernel-module--permission-error)
  * [2. swtpm socket connection failures](#2-swtpm-socket-connection-failures)
  * [3. Permission denied on /dev/net/tun](#3-permission-denied-on-devnettun)
  * [4. Internet works but VMs can't ping each other](#4-internet-works-but-vms-cant-ping-each-other)
  * [5. VM boots but display is laggy or screen is black](#5-vm-boots-but-display-is-laggy-or-screen-is-black)

---

# What actually is troubleshooting?

Troubleshooting isn't just copy-pasting commands from Google or ChatGPT. It's a logical, step-by-step search for the root cause of a problem.

When QEMU crashes, it always outputs an error message. Instead of ignoring it, we read the error, isolate the part of the system that failed (Is it a file permission issue? A missing driver? A wrong config path?), and fix that specific thing. 

---

# Why do we need to learn this?

Our lab uses multiple connected components:
* The Linux kernel (KVM module)
* System permissions (your user group, `/dev/kvm`, `/dev/net/tun` rules)
* Companion daemons (like `swtpm` for TPM emulation)
* Network adapters and kernel bridges (`br0` and `tap3`)
* UEFI files (OVMF paths)

If even *one* of these things is misconfigured, the VM won't boot. Knowing how to trace the error along this chain saves you from wasting hours of setup time.

---

# The Career Cheat Code (Why this is the best skill to learn)

Honestly, in college labs, we're taught to just run commands. But in a real job (software engineering, DevOps, or cybersec), things break constantly.

* **It makes you the go-to person**: Anyone can copy-paste commands when they work. The engineers who get paid the big bucks are the ones who can look at a blank screen or a stack trace and immediately guess where the pipe broke.
* **Saves your sanity**: Instead of nuking your entire VM directory and starting from scratch, you can find the exact permission flag that is off and fix it in 2 minutes.

---

# Most common errors in our lab & How to fix them

Here are the exact errors we ran into while setting this lab up on Arch Linux, along with simple steps to fix them:

### 1. The KVM kernel module / permission error
* **The Error**: `Could not access KVM kernel module: No such file or directory` or `Failed to initialize KVM: Permission denied`.
* **Why it happens**: Either virtualization is disabled in your system's BIOS settings, or your current user isn't in the `kvm` group.
* **The Fix**:
  1. Reboot your machine, go into BIOS settings, and make sure **SVM (AMD)** or **Intel VT-x** is enabled.
  2. Add your user to the `kvm` and `libvirt` groups:
     ```bash
     sudo usermod -aG kvm,libvirt $USER
     ```
  3. Log out and log back in (or reboot) for the changes to apply.

### 2. `swtpm` socket connection failures
* **The Error**: `Failed to connect to socket /home/user/VMs/win11/tpm/swtpm-sock: Connection refused`.
* **Why it happens**: You started QEMU, but you forgot to start the `swtpm` background process first, or the daemon crashed.
* **The Fix**: Start the daemon manually before running QEMU:
  ```bash
  swtpm socket --tpmstate dir=$HOME/VMs/win11/tpm --ctrl type=unixio,path=$HOME/VMs/win11/tpm/swtpm-sock --tpm2 --daemon
  ```
  Double check if it is active: `ps aux | grep swtpm`.

### 3. Permission denied on `/dev/net/tun`
* **The Error**: `open /dev/net/tun: Permission denied` or QEMU fails to bind to the TAP interface.
* **Why it happens**: Creating network interfaces is a root-only task, or the TAP interface is owned by `root` instead of your user.
* **The Fix**: When creating the TAP interface, you *must* assign ownership to your local user:
  ```bash
  sudo ip tuntap add name tap3 mode tap user $USER
  ```
  If it was already created by root, delete it (`sudo ip link delete tap3`) and recreate it correctly.

### 4. Internet works but VMs can't ping each other
* **The Error**: You can ping `google.com` (via the NAT interface), but you cannot ping `192.168.100.20` (Windows VM) from Kali Linux.
* **Why it happens**: 
  1. The TAP interfaces are not bound to the `br0` bridge.
  2. Windows Defender firewall blocks ICMP (ping) traffic by default.
* **The Fix**:
  1. On the host, verify the bridge links: `ip link show master br0`. If `tap3` or `tap4` is missing, plug them in: `sudo ip link set dev tap3 master br0`.
  2. In the Windows 11 VM, open **Windows Defender Firewall** -> **Advanced Settings** -> **Inbound Rules**, search for **File and Printer Sharing (Echo Request - ICMPv4-In)** and enable it.

### 5. VM boots but display is laggy or screen is black
* **The Error**: Windows 11 runs, but moving windows is extremely laggy, or the GUI screen doesn't show up.
* **Why it happens**: QEMU is using software graphics rendering because hardware-accelerated OpenGL graphics are misconfigured.
* **The Fix**: Make sure your launch command uses:
  ```text
  -display gtk,gl=on -device virtio-vga-gl
  ```
  This tells QEMU to pass graphics rendering tasks directly to your host's GPU.
