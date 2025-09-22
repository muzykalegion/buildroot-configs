## Configuration files for Buildroot

List of available configs:
- Raspberry Pi 4
  - [board-module](raspberry_pi_4/board-module)
  - [handset-module](raspberry_pi_4/handset-module)
- Raspberry Pi Zero 2W
  - [base](raspberry_pi_zero_2w/base) 

### Instructions

To apply config clone Buildroot project (**NOTE**: the configs built with version `2025.05`)

```bash
cd ~/workspace
git clone https://github.com/buildroot/buildroot.git
```
(Optional) Checkout a specific version:

```bash
git checkout 2025.05
```

Copy all the content from desired platform/module folder into buildroot's directory.\
Corresponding `.config` (and `flash_rpi.sh` which is optional) should appear under buildroot main dir, specific contents goes to `buildroot/board/<platform-module>` \
E.g. to build RPiZero2W _base_ config the contents of `raspberry_pi_zero_2w/base/buildroot` should go to `~/workspace/buildroot` or whatever dir Buildroot cloned to.

---
❗ **NOTE**: Might need to update `.config` to specify correct path

    BR2_DEFCONFIG="/media/muzyka/1TB/buildroot/configs/raspberrypizero2w_64_defconfig"

Next command should set this 
```bash
make raspberrypizero2w_64_defconfig
```
---
⚠️ **NOTE**: Do not forget to review and set up your _Wi-Fi config_ in corresponding `buildroot/board/<board>/post-build.sh` script 

---

### Configuration

- In order to set up **linux kernel** config run: 
```bash
cd ~/workspace/buildroot
make linux-xconfig
```
This preconfigured already in `linux.config` file and set in `.config` as 

    BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="board/rpizero2w-base/linux.config"
**However**, the changes themselves are stored in `buildroot/output/build/linux-custom/.config`

- Almost all the software/hardware specifics configuration saved in `.config`.  
In order to set up **software/hardware specifics** run:
```bash
cd ~/workspace/buildroot
make xconfig
```
The changes will be saved in `.config` file under Buildroot's root dir.

## Flash SD Card
See [BUILDROOT.md](BUILDROOT.md)


