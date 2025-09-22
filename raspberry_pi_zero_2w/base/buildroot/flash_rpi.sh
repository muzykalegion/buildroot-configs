#!/bin/bash

#set -e  # Exit on error

# Ensure device is provided
if [ -z "$1" ]; then
    echo "❌ Error: No device specified. Find your device with lsblk command."
    echo "Usage: $0 /dev/sdX"
    exit 1
fi

DEVICE="$1"        # Change if your SD card is on a different device
BOOT_PART=${DEVICE}1
ROOT_PART=${DEVICE}2

MOUNT_BOOT=/mnt/rpi/boot
MOUNT_ROOTFS=/mnt/rpi/rootfs
MOUNT_IMG=/mnt/rootimg

# 0. Mount partitions
echo "🗄  Unmounting partitions..."
sudo umount "$BOOT_PART"
sudo umount "$ROOT_PART"

# 1. Format partitions
echo "🗂  Formatting ${BOOT_PART} as FAT32..."
sudo mkfs.vfat -F 32 "$BOOT_PART"

echo "🗂  Formatting ${ROOT_PART} as ext4..."
sudo mkfs.ext4 -F "$ROOT_PART"

# 2. Create mount points
sudo mkdir -p "$MOUNT_BOOT" "$MOUNT_ROOTFS" "$MOUNT_IMG"

# 3. Mount partitions
echo "🗃  Mounting partitions..."
sudo mount "$BOOT_PART" "$MOUNT_BOOT"
sudo mount "$ROOT_PART" "$MOUNT_ROOTFS"

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
