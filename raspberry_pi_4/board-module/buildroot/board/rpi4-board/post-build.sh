#!/bin/sh

echo "Running post-build.sh" > /tmp/post-build.log
echo "TARGET_DIR=$TARGET_DIR" >> /tmp/post-build.log
ls -l $TARGET_DIR/etc/init.d/rcS >> /tmp/post-build.log
cat $TARGET_DIR/etc/init.d/rcS >> /tmp/post-build.log

# Creating directory structure
mkdir -p $TARGET_DIR/etc/ssh
mkdir -p $TARGET_DIR/etc/init.d
mkdir -p $TARGET_DIR/etc/rcS.d
mkdir -p $TARGET_DIR/etc/modprobe.d
mkdir -p $TARGET_DIR/boot

mkdir -p $TARGET_DIR/lib/firmware/brcm
mkdir -p $TARGET_DIR/lib/firmware/cypress

# Copy brcmfmac firmware
cp board/rpi4-handset/firmware/brcmfmac43455-sdio.* $TARGET_DIR/lib/firmware/brcm/
cp board/rpi4-handset/firmware/brcmfmac43455-sdio.* $TARGET_DIR/lib/firmware/cypress/
chmod 644 $TARGET_DIR/lib/firmware/brcm/brcmfmac43455-sdio.*
chmod 644 $TARGET_DIR/lib/firmware/cypress/cyfmac43455-sdio.*
echo "Copied brcmfmac firmware files to brcm: $?" >> /tmp/post-build.log
echo "Copied cyfmac firmware files to cypress: $?" >> /tmp/post-build.log

# Remove conflicting symlinks
rm -f $TARGET_DIR/lib/firmware/brcm/brcmfmac43455-sdio.bin
rm -f $TARGET_DIR/lib/firmware/brcm/brcmfmac43455-sdio.clm_blob
rm -f $TARGET_DIR/lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.*
echo "Removed brcm symlinks: $?" >> /tmp/post-build.log

# Copy firmware files directly (no symlinks)
cp board/rpi4-handset/firmware/brcmfmac43455-sdio.bin $TARGET_DIR/lib/firmware/brcm/brcmfmac43455-sdio.bin
cp board/rpi4-handset/firmware/brcmfmac43455-sdio.clm_blob $TARGET_DIR/lib/firmware/brcm/brcmfmac43455-sdio.clm_blob
echo "Copied direct brcmfmac firmware files: $?" >> /tmp/post-build.log

# Copy regulatory.db files
cp board/rpi4-board/firmware/regulatory.db $TARGET_DIR/lib/firmware/regulatory.db
cp board/rpi4-board/firmware/regulatory.db.p7s $TARGET_DIR/lib/firmware/regulatory.db.p7s
chmod 644 $TARGET_DIR/lib/firmware/regulatory.db*

# Remove misplaced files in /etc/
rm -f $TARGET_DIR/etc/S40network $TARGET_DIR/etc/S50sshd
# Remove S50pigpio installed by pigpio package
rm -f $TARGET_DIR/etc/init.d/S50pigpio $TARGET_DIR/etc/rcS.d/S50pigpio
echo "Removed S50pigpio: $?" >> /tmp/post-build.log

# Create fstab
cat << 'EOF' > $TARGET_DIR/etc/fstab
# <device> <mount point> <type> <options> <dump> <pass>
sysfs /sys sysfs defaults 0 0
proc /proc proc defaults 0 0
tmpfs /tmp tmpfs defaults 0 0
devpts /dev/pts devpts defaults,gid=5,mode=620 0 0
/dev/mmcblk0p1 /boot vfat defaults 0 0
EOF
chmod 644 $TARGET_DIR/etc/fstab

# Modprobe 
cat << 'EOF' > $TARGET_DIR/etc/init.d/S10uvc
#!/bin/sh
# Load EasyCAP / UVC driver
case "$1" in
  start)
    echo "Loading uvcvideo..."
    modprobe uvcvideo
    ;;
  stop)
    echo "Unloading uvcvideo..."
    rmmod uvcvideo
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
    ;;
esac

exit 0
EOF
chmod +x $TARGET_DIR/etc/init.d/S10uvc

# Create pipeline
cat << 'EOF' > $TARGET_DIR/etc/init.d/S11gst
#!/bin/sh
case "$1" in
  start)
    echo "Starting GStreamer pipeline..."
    (
      sleep 1
      gst-launch-1.0 v4l2src ! image/jpeg,width=640,height=480,framerate=60/1 ! queue ! v4l2jpegdec ! video/x-raw,format=RGB16 ! queue ! videoconvert ! queue ! fbdevsink > /tmp/gst.log 2>&1
    ) &
    ;;
  stop)
    echo "Stopping GStreamer pipeline..."
    # Find and kill gst-launch-1.0 processes (be careful if you run multiple!)
    pkill gst-launch-1.0
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
    ;;
esac

exit 0
EOF
chmod +x $TARGET_DIR/etc/init.d/S11gst

cat << 'EOF' > $TARGET_DIR/etc/init.d/rcS
#!/bin/sh
# Start all init scripts in /etc/init.d
# executing them in numerical order.
#
for i in /etc/init.d/S??* ;do

     # Ignore dangling symlinks (if any).
     [ ! -f "$i" ] && continue

     case "$i" in
	*.sh)
	    # Source shell script for speed.
	    (
		trap - INT QUIT TSTP
		set start
		. "$i"
	    )
	    ;;
	*)
	    # No sh extension, so fork subprocess.
	    "$i" start
	    ;;
     esac
done
EOF
chmod +x $TARGET_DIR/etc/init.d/rcS

# Create network startup script with debug logging
  cat << 'EOF' > $TARGET_DIR/etc/init.d/S40network
  #!/bin/sh
  echo "Script invoked with arg: '$1'" > /tmp/network.log
  case "$1" in
    start)
      echo "Starting Wi-Fi..." >> /tmp/network.log
      modprobe brcmutil >> /tmp/network.log 2>&1
      echo "brcmutil loaded: $?" >> /tmp/network.log
      modprobe brcmfmac >> /tmp/network.log 2>&1
      echo "brcmfmac loaded: $?" >> /tmp/network.log
      for i in {1..10}; do
        [ -d /sys/class/net/wlan0 ] && break
        echo "Waiting for wlan0 ($i)..." >> /tmp/network.log
        sleep 0.3
      done
      if [ -d /sys/class/net/wlan0 ]; then
        ifconfig wlan0 up >> /tmp/network.log 2>&1
        echo "wlan0 up: $?" >> /tmp/network.log
        iw reg get >> /tmp/network.log 2>&1
        echo "reg get: $?" >> /tmp/network.log
        wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf >> /tmp/network.log 2>&1
        echo "wpa_supplicant started: $?" >> /tmp/network.log
        udhcpc -i wlan0 >> /tmp/network.log 2>&1
        echo "udhcpc: $?" >> /tmp/network.log
        iw dev wlan0 link >> /tmp/network.log 2>&1
        echo "wlan0 link status: $?" >> /tmp/network.log
      else
        echo "wlan0 not found" >> /tmp/network.log
      fi
      ;;
    stop)
      echo "Stopping Wi-Fi..." >> /tmp/network.log
      killall wpa_supplicant 2>/dev/null
      ifconfig wlan0 down 2>/dev/null
      modprobe -r brcmfmac 2>/dev/null
      modprobe -r brcmutil 2>/dev/null
      ;;
    *)
      echo "Usage: $0 {start|stop}" >> /tmp/network.log
      exit 1
      ;;
  esac
exit 0
EOF
chmod +x $TARGET_DIR/etc/init.d/S40network
ln -sf /etc/init.d/S40network $TARGET_DIR/etc/rcS.d/S40network
  
# Create brcmfmac config
echo "options brcmfmac feature_disable=0x82000" > $TARGET_DIR/etc/modprobe.d/brcmfmac.conf
chmod 644 $TARGET_DIR/etc/modprobe.d/brcmfmac.conf

# Creating wpa_supplicant.conf with Wi-Fi credentials
cat << 'EOF' > $TARGET_DIR/etc/wpa_supplicant.conf
country=UA
network={
    ssid="YOUR_WIFI"
    psk="YOUR_PASSWORD"
}
EOF
chmod 600 $TARGET_DIR/etc/wpa_supplicant.conf

# Generating SSH host keys
if [ ! -f $TARGET_DIR/etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -t rsa -f $TARGET_DIR/etc/ssh/ssh_host_rsa_key -N ""
fi
if [ ! -f $TARGET_DIR/etc/ssh/ssh_host_ecdsa_key ]; then
    ssh-keygen -t ecdsa -f $TARGET_DIR/etc/ssh/ssh_host_ecdsa_key -N ""
fi
if [ ! -f $TARGET_DIR/etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f $TARGET_DIR/etc/ssh/ssh_host_ed25519_key -N ""
fi
chmod 600 $TARGET_DIR/etc/ssh/ssh_host_*_key
chmod 644 $TARGET_DIR/etc/ssh/ssh_host_*_key.pub

# Creating SSH startup script
cat << 'EOF' > $TARGET_DIR/etc/init.d/S50sshd
#!/bin/sh
now_ts() {
    awk '{printf "[ %10.6f] ", $1}' /proc/uptime
}
case "$1" in
  start)
    echo "$(now_ts) Starting sshd..."
    /usr/sbin/sshd
    ;;
  stop)
    echo "$(now_ts) Stopping sshd..."
    killall sshd
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
exit 0
EOF
chmod +x $TARGET_DIR/etc/init.d/S50sshd
ln -sf /etc/init.d/S50sshd $TARGET_DIR/etc/rcS.d/S50sshd

# Create sshd_config
cat << 'EOF' > $TARGET_DIR/etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes
#KbdInteractiveAuthentication no
EOF
chmod 644 $TARGET_DIR/etc/ssh/sshd_config

