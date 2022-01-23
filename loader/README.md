# LKM

```bash
# build dts and copy it to /boot/overlays
dtc -@ -I dts -O dtb -o ice40-overlay.dtbo ice40-overlay.dts

# load regmap-i2c if compiled as module
modprobe regmap-i2c
insmod fpga-loader.ko
```

## Raspberry PI Kernel stuff

see https://www.raspberrypi.com/documentation/computers/linux_kernel.html#kernel-headers

enable __fpga manager__ and __ice40 loader__

```bash
cd linux
KERNEL=kernel7l
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2711_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
```

```bash
BOOT=/media/andrehn/boot
ROOT=/media/andrehn/rootfs

sudo cp $BOOT/$KERNEL.img $BOOT/$KERNEL-backup.img
sudo cp arch/arm/boot/zImage $BOOT/$KERNEL.img
sudo cp arch/arm/boot/dts/*.dtb $BOOT/
sudo cp arch/arm/boot/dts/overlays/*.dtb* $BOOT/overlays/
sudo cp arch/arm/boot/dts/overlays/README $BOOT/overlays/
sudo umount $BOOT

sudo env PATH=$PATH make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=$ROOT modules_install
sudo umount $ROOT
```