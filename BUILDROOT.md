# 📑 Raspberry Pi Manual Installation (Buildroot Output)

# 🧰 Buildroot Raspberry Pi Build Instructions

This document provides a minimal guide to clone, configure, and build a Buildroot image for the Raspberry Pi 4.

---

## 🧱 1. Clone Buildroot

```bash
mkdir -p ~/rpi-buildroot && cd ~/rpi-buildroot
git clone https://github.com/buildroot/buildroot.git
cd buildroot
```

(Optional) Checkout a specific version:

```bash
git checkout 2025.05
```

---

## ⚙️ 2. Configure Buildroot

Use the predefined Raspberry Pi 4 64-bit configuration:

```bash
make raspberrypi4_64_defconfig
```

Copy [board](buildroot/board) folder content to buildroot/ folder

Add next line to `buildroot/package/Config.in`:
```text
source "package/yamspy/Config.in"
source "package/python-board-module/Config.in"
```

Then customise via `menuconfig` or `xconfig`:

```bash
make xconfig
```

⚠️ Might need to install `pip` and `pyserial` on **host python3** in order to build _YAMSpy_
```shell
output/host/usr/bin/python3 -m ensurepip --default-pip
output/host/usr/bin/python3 -m pip install pyserial
```

---

## 🛠 3. Build the Image

```bash
make -j$(nproc)
```

> This will take a while depending on your machine.

---

## 📂 4. Output Files

After build completion, check `output/images/`:

* `Image` – Linux kernel
* `rootfs.ext4` – Root filesystem
* `rpi-firmware/` – Bootloader files (with `config.txt`, `cmdline.txt`, overlays, etc.)
* `*.dtb` – Device Tree Blobs for supported boards

---

# 💾 Creating bootable SD card

This guide explains how to manually install a Buildroot-generated Raspberry Pi 4 image onto an SD card.

## 📟 You Should Have These Files (from `output/images/`)

* `Image` – Linux kernel
* `rootfs.ext4` – Root filesystem
* `rpi-firmware/` – Raspberry Pi boot firmware
* (Optional) `*.dtb` files if needed for device-specific overlays

---

## 💠 Step 1: Prepare SD Card

List available block devices:

```bash
lsblk
sudo fdisk -l
```

Find your SD card device (e.g., `/dev/sdb`) and replace `/dev/sdX` in the commands below.  

⚠ **Warning:** This will erase all data on the SD card. Double-check the device name before proceeding.

---

## 2. Partition the SD Card

### Interactive Method (`fdisk`)

```bash
sudo fdisk /dev/sdX
```

#### Steps:
1. Press `o` — create a new empty **DOS** partition table (MBR)

2. Create Partition 1 (Boot)
   - Press `n` — new partition
   - Type: **primary** (`p`)
   - Partition number: `1`
   - First sector: press **Enter**
   - Last sector: `+256M`
   - Press `t` — change partition type → `c` (**W95 FAT32 (LBA)**)

3. Create Partition 2 (Root)
   - Press `n` — new partition
   - Type: **primary** (`p`)
   - Partition number: `2`
   - First sector: press **Enter**
   - Last sector: press **Enter`
   - Press `t` → select partition `2` → type `83` (**Linux**)

4. Press `w` — write changes and exit

---

### Automated Method (`sfdisk`)

```bash
sudo sfdisk /dev/sdX << EOF
,256M,c
,,83
EOF
```

Explanation
- `,256M,c` → First partition, 256 MB, type c (W95 FAT32 LBA)
- `,,83` → Second partition, remaining space, type 83 (Linux)

--- 
### ⬇️ All the steps below are automated in [flash_rpi.sh](buildroot/flash_rpi.sh) - put it inside root folder of the **Buildroot**


Then format:

```bash
sudo mkfs.vfat -F 32 /dev/sdb1
sudo mkfs.ext4 /dev/sdb2
```

> ⚠️ Replace `/dev/sdX` with your actual SD card device.

---

## 📂 Step 2: Mount Partitions

```bash
mkdir -p /mnt/rpi/boot /mnt/rpi/rootfs

sudo mount /dev/sdX1 /mnt/rpi/boot
sudo mount /dev/sdX2 /mnt/rpi/rootfs
```

---

## 📁 Step 3: Copy Files

### Copy to Boot Partition:

```bash
sudo cp -r output/images/rpi-firmware/* /mnt/rpi/boot/
sudo cp output/images/*.dtb /mnt/rpi/boot/
sudo cp output/images/Image /mnt/rpi/boot/kernel8.img
```

### Copy Root Filesystem:

Extract from ext4 image

```bash
sudo mkdir /mnt/rootimg
sudo mount output/images/rootfs.ext4 /mnt/rootimg
sudo cp -a /mnt/rootimg/* /mnt/rpi/rootfs/
sudo umount /mnt/rootimg
```
---

## ✍️ Step 4: Edit Boot Configuration Files

### `config.txt` (in `/mnt/rpi/boot/`):

```ini
enable_uart=1
dtoverlay=uart1
dtoverlay=uart2
dtoverlay=uart3
sdtv_mode=2        # PAL (0 for NTSC)
enable_tvout=1     # Optional
```

### `cmdline.txt`:

```
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootwait
```

---

## ✅ Step 5: Finalize and Boot

```bash
sync
sudo umount /mnt/rpi/boot /mnt/rpi/rootfs
```

Insert SD card into the Raspberry Pi and boot it. Adjust `config.txt` and `cmdline.txt` as needed for UARTs or AV output.

---
