MODULENAME 	:= fpga-loader
obj-m 	   	:= $(MODULENAME).o

KDIR		:= $(shell pwd)/../../linux
PWD 	   	:= $(shell pwd)

KERNEL		:=kernel7l
MAKE:=make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -Wall 

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	rm -rf *.o *.ko *.mod.c *.mod *~ .*.cmd *.o.cmd .*.o.cmd \
	Module.symvers modules.order .tmp_versions modules.builtin

modules_install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install

copy:
	scp $(MODULENAME).ko pi@192.168.178.35: