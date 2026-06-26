# VM Snapshots: The Ultimate Lifesaver for virtual labs

If you are doing malware analysis, testing exploits, or editing system registry files in your lab, you *will* break your VMs. It's not a matter of if, but when. 

Honestly, re-installing Windows 11 or setting up a clean Kali Linux machine from scratch every single time is a massive waste of time. This is why snapshots are absolute lifesavers.

Think of a snapshot like a checkpoint or a "save game" state in a video game. You save the VM's clean state, go run a malware sample or mess with system files, and then instantly teleport back to your clean checkpoint in less than 5 seconds.

---

## What we're covering:

* [Internal vs External: What's the difference?](#internal-vs-external-whats-the-difference)
* [Taking snapshots when the VM is turned off (Offline)](#taking-snapshots-when-the-vm-is-turned-off-offline)
  * [1. Creating a snapshot](#1-creating-a-snapshot)
  * [2. Checking your saved snapshots](#2-checking-your-saved-snapshots)
  * [3. Going back in time (Restoring)](#3-going-back-in-time-restoring)
  * [4. Deleting old snapshots](#4-deleting-old-snapshots)
* [Taking live snapshots (While the VM is running)](#taking-live-snapshots-while-the-vm-is-running)
* [Things to keep in mind (so you don't break stuff)](#things-to-keep-in-mind-so-you-dont-break-stuff)

---

# Internal vs External: What's the difference?

Before we start typing commands, you should know that QEMU has two ways of doing snapshots. Since we are using the **QCOW2** disk format, we can use either:

### 1. Internal Snapshots
Everything is saved inside our single `.qcow2` file itself. The virtual disk keeps both the base state and the changes in the same file. It's super convenient because you only have one file to copy or backup.

### 2. External Snapshots
Here, QEMU freezes your original disk image (`win11.qcow2`) as read-only and creates a new overlay file (like `win11-overlay.qcow2`). All new writes go to this overlay. It's faster for running VMs, but it makes file management messy because you end up with a chain of dependent files.

For our lab, **Internal Snapshots** are much easier to manage, so we will use them.

---

# Taking snapshots when the VM is turned off (Offline)

*Super important note: Make sure your virtual machine is **completely shut down** before running these commands. If you try to modify the disk of a running VM from the host terminal, you will corrupt the virtual disk!*

### 1. Creating a snapshot
Let's say you just finished installing Windows 11 and all the drivers. Before you test any malware or tweak settings, create a snapshot named `clean_install`:

```bash
qemu-img snapshot -c clean_install ~/VMs/win11/win11.qcow2
```

* `-c clean_install` tells it to create a snapshot named `clean_install`.
* The last path is just the path to your VM's `.qcow2` disk.

### 2. Checking your saved snapshots
To see what snapshots you have stored inside the virtual disk, run:

```bash
qemu-img snapshot -l ~/VMs/win11/win11.qcow2
```

You should see something like this:

```text
Snapshot list:
ID        TAG                 VM SIZE                DATE       VM CLOCK
1         clean_install           0 B 2026-06-26 14:00:00   00:00:00.000
```
*(The `VM SIZE` is `0 B` because the VM was offline, so it only saved the disk state and didn't need to dump the active RAM).*

### 3. Going back in time (Restoring)
If you accidentally ran a payload, caught a virus, or broke your registry, turn off the VM and run this to revert the disk back to your `clean_install` checkpoint:

```bash
qemu-img snapshot -a clean_install ~/VMs/win11/win11.qcow2
```

* `-a clean_install` tells it to "apply" the snapshot.
* Once the command finishes (takes just a second), you can boot the VM up. It will be exactly as it was when you took the snapshot.

### 4. Deleting old snapshots
If you want to free up space or don't need an old checkpoint anymore:

```bash
qemu-img snapshot -d clean_install ~/VMs/win11/win11.qcow2
```

* `-d` stands for delete.

---

# Taking live snapshots (While the VM is running)

If you don't want to shut down your VM to take a snapshot, you can do it live. This will save the active RAM state as well, meaning when you restore it, the VM boots up with all your open terminal tabs and folders exactly as you left them.

To do this, we talk to the **QEMU Monitor**.

If you ran QEMU from your terminal, you can press **`Ctrl + Alt + 2`** on your keyboard to switch from the VM screen to the QEMU Monitor console (and **`Ctrl + Alt + 1`** to switch back to the VM).

Inside the QEMU Monitor, run these:

* **Save the running state**:
  ```text
  savevm snapshot_active
  ```
  *(Note: The VM might freeze for a few seconds while it writes the virtual RAM to disk).*

* **List your snapshots**:
  ```text
  info snapshots
  ```

* **Restore the running state**:
  ```text
  loadvm snapshot_active
  ```

* **Delete the state**:
  ```text
  delvm snapshot_active
  ```

---

# Things to keep in mind (so you don't break stuff)

* **RAW images don't support this**: If your virtual disk is in `.img` or raw format, `qemu-img snapshot` won't work. You must use **QCOW2** for internal snapshots.
* **Keep an eye on disk space**: Every time you make changes after taking a snapshot, the `.qcow2` file grows because it has to keep track of the differences. If you do a lot of heavy writes, the file will balloon up quickly. Use `df -h` on your host to check your disk space.
* **Delete snapshots before backing up**: If you plan to copy your VM folder to an external drive as a backup, delete any snapshots you don't need. Otherwise, you'll be copying a massive, bloated file.
