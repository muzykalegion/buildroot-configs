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
mkdir -p $TARGET_DIR/lib/firmware/synaptics

# Copy brcmfmac firmware
cp -a -P board/rpizero2w-base/firmware/brcm/* $TARGET_DIR/lib/firmware/brcm/
cp -a -P board/rpizero2w-base/firmware/cypress/* $TARGET_DIR/lib/firmware/cypress/
cp -a -P board/rpizero2w-base/firmware/synaptics/* $TARGET_DIR/lib/firmware/synaptics/

chmod 644 $TARGET_DIR/lib/firmware/brcm/*
chmod 644 $TARGET_DIR/lib/firmware/cypress/*
chmod 644 $TARGET_DIR/lib/firmware/synaptics/*
echo "Copied brcmfmac firmware files: $?" >> /tmp/post-build.log

# Copy regulatory.db files
cp board/rpizero2w-base/firmware/regulatory.db $TARGET_DIR/lib/firmware/regulatory.db
cp board/rpizero2w-base/firmware/regulatory.db.p7s $TARGET_DIR/lib/firmware/regulatory.db.p7s
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

# Create loopback startup script
cat << 'EOF' > $TARGET_DIR/etc/init.d/S10loopback
#!/bin/sh
#
# Enable loopback interface on boot
#
echo "S10loopback invoked with arg: '$1'" > /tmp/loopback.log
case "$1" in
  start)
    echo "Enabling loopback interface..." >> /tmp/loopback.log
    /sbin/ip link set lo up >> /tmp/loopback.log 2>&1
    echo "ip link set lo up: $?" >> /tmp/loopback.log
    /sbin/ip addr add 127.0.0.1/8 dev lo >> /tmp/loopback.log 2>&1
    echo "ip addr add 127.0.0.1/8 dev lo: $?" >> /tmp/loopback.log
    ;;
  stop)
    echo "Disabling loopback interface..." >> /tmp/loopback.log
    /sbin/ip addr del 127.0.0.1/8 dev lo 2>/dev/null
    echo "ip addr del: $?" >> /tmp/loopback.log
    /sbin/ip link set lo down 2>/dev/null
    echo "ip link set lo down: $?" >> /tmp/loopback.log
    ;;
  *)
    echo "Usage: $0 {start|stop}" >> /tmp/loopback.log
    exit 1
    ;;
esac
exit 0
EOF
chmod +x $TARGET_DIR/etc/init.d/S10loopback
ln -sf /etc/init.d/S10loopback $TARGET_DIR/etc/rcS.d/S10loopback

# Create pigpiod startup script
cat << 'EOF' > $TARGET_DIR/etc/init.d/S11pigpiod
#!/bin/sh
#
# Start pigpiod daemon on boot
#
echo "S11pigpiod invoked with arg: '$1'" > /tmp/pigpiod.log
case "$1" in
  start)
    echo "Starting pigpiod..." >> /tmp/pigpiod.log
    /usr/bin/pigpiod -n 127.0.0.1 -p 8888 >> /tmp/pigpiod.log 2>&1
    echo "pigpiod started: $?" >> /tmp/pigpiod.log
    ;;
  stop)
    echo "Stopping pigpiod..." >> /tmp/pigpiod.log
    /usr/bin/pkill pigpiod 2>/dev/null
    echo "pigpiod stopped: $?" >> /tmp/pigpiod.log
    ;;
  *)
    echo "Usage: $0 {start|stop}" >> /tmp/pigpiod.log
    exit 1
    ;;
esac
exit 0
EOF
chmod +x $TARGET_DIR/etc/init.d/S11pigpiod
ln -sf /etc/init.d/S11pigpiod $TARGET_DIR/etc/rcS.d/S11pigpiod

# Enable UVC module
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
        sleep 0.5
      done
      if [ -d /sys/class/net/wlan0 ]; then
        ifconfig wlan0 up >> /tmp/network.log 2>&1
        echo "wlan0 up: $?" >> /tmp/network.log
        iw reg get >> /tmp/network.log 2>&1
        echo "reg get: $?" >> /tmp/network.log
        iw reg set UA
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
echo "options brcmfmac roamoff=1 feature_disable=0x82000 debug=0x15" > $TARGET_DIR/etc/modprobe.d/brcmfmac.conf
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


