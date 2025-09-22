#!/bin/bash

# Detect if sourced
(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0

# Ensure device is provided
if [ -z "$1" ]; then
    echo "❌ Error: No device specified. Find the device with lsblk command."
    echo "Usage: $0 /dev/sdX"
    if [ "$SOURCED" -eq 1 ]; then
        return 1
    else
        exit 1
    fi
fi

DEVICE="$1"        # e.g. /dev/sdX
BOOT_PART=${DEVICE}1
ROOT_PART=${DEVICE}2

MOUNT_BOOT=/mnt/rpi/boot
MOUNT_ROOTFS=/mnt/rpi/rootfs
MOUNT_IMG=/mnt/rootimg

# 0. Unmount partitions if mounted
echo "🗄  Unmounting partitions..."
sudo umount "$BOOT_PART" 2>/dev/null
sudo umount "$ROOT_PART" 2>/dev/null

# 1. Format partitions with labels
echo "🗂  Formatting ${BOOT_PART} as FAT32 (bootfs)..."
sudo mkfs.vfat -F 32 -n bootfs "$BOOT_PART"

echo "🗂  Formatting ${ROOT_PART} as ext4 (rootfs)..."
sudo mkfs.ext4 -F -L rootfs "$ROOT_PART"

# 2. Create mount points
sudo mkdir -p "$MOUNT_BOOT" "$MOUNT_ROOTFS" "$MOUNT_IMG"

# 3. Mount by label (safer than /dev/sdX order)
echo "🗃  Mounting partitions by label..."
sudo mount -L bootfs "$MOUNT_BOOT"
sudo mount -L rootfs "$MOUNT_ROOTFS"

# 4. Copy boot files
echo "💽 Copying firmware and kernel..."
sudo cp -r output/images/rpi-firmware/* "$MOUNT_BOOT/"
sudo cp output/images/*.dtb "$MOUNT_BOOT/"
sudo cp output/images/Image "$MOUNT_BOOT/kernel8.img"

# 5. Mount rootfs image
echo "🗃  Mounting rootfs image..."
sudo mount output/images/rootfs.ext4 "$MOUNT_IMG"

# 6. Copy root filesystem
echo "💽 Copying root filesystem..."
sudo cp -a "$MOUNT_IMG"/* "$MOUNT_ROOTFS/"

# 7. Cleanup
echo "🧹 Cleaning up..."
sync
sudo umount "$MOUNT_IMG"
sudo umount "$MOUNT_BOOT" "$MOUNT_ROOTFS"

# 8. Eject device
sudo eject "$DEVICE"

echo "✅ Done: SD card prepared for Raspberry Pi."
echo "💻 You can safely remove the USB device."