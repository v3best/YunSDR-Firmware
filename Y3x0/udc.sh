#!/bin/sh

PRODUCT="YunSDR"
USBPID=0xb673
ENDPOINTS=3

#S40network / S41network
UDHCPD_CONF=/etc/udhcpd.conf
CONF=/opt/config.txt
IFAC=/etc/network/interfaces


CONFIGFS=/sys/kernel/config/usb_gadget
GADGET=$CONFIGFS/composite_gadget


case "$1" in
  start)
        echo -n "Starting UDC Gadgets: "
        modprobe configfs
        modprobe libcomposite
        
        mount -t configfs none /sys/kernel/config 2> /dev/null

        mkdir -p $GADGET

        model=`cat /sys/firmware/devicetree/base/model | tr / -`
        PRODUCT="YunSDR-Y320"
        serial="11111111111111111111"

        echo 0x0456 > $GADGET/idVendor
        echo $USBPID > $GADGET/idProduct

        mkdir -p $GADGET/strings/0x409
        echo "V3Best Inc." > $GADGET/strings/0x409/manufacturer
        echo $PRODUCT > $GADGET/strings/0x409/product
        echo $serial > $GADGET/strings/0x409/serialnumber

        mkdir -p $GADGET/functions/acm.usb0
        #mkdir -p $GADGET/functions/eem.usb0
        mkdir -p $GADGET/functions/rndis.0
        mkdir -p $GADGET/functions/mass_storage.0

        echo /dev/mmcblk0p1 > $GADGET/functions/mass_storage.0/lun.0/file
        echo Y > $GADGET/functions/mass_storage.0/lun.0/removable

        #host_addr=`echo -n 00:E0:22; echo $sha1 | dd bs=1 count=6 2>/dev/null | hexdump -v -e '/1 ":%01c""%c"'`
        #dev_addr=`echo -n 00:05:F7; echo $sha1 | dd bs=1 count=6 skip=6 2>/dev/null | hexdump -v -e '/1 ":%01c""%c"'`

        #echo $host_addr > $GADGET/functions/rndis.0/host_addr
        #echo $dev_addr > $GADGET/functions/rndis.0/dev_addr

        mkdir -p $GADGET/configs/c.1
        mkdir -p $GADGET/configs/c.1/strings/0x409
        echo "RNDIS/MSD/ACM" > $GADGET/configs/c.1/strings/0x409/configuration
        echo 500 > $GADGET/configs/c.1/MaxPower

        ln -s $GADGET/functions/rndis.0 $GADGET/configs/c.1
        ln -s $GADGET/functions/mass_storage.0 $GADGET/configs/c.1
        ln -s $GADGET/functions/acm.usb0 $GADGET/configs/c.1
        #ln -s $GADGET/functions/eem.usb0 $GADGET/configs/c.1

        sleep 2

        echo ci_hdrc.0 > $GADGET/UDC

        [ $? = 0 ] && echo "OK" || echo "FAIL"
        
        echo 'S0:12345:respawn:/bin/start_getty 115200 ttyGS0' >> /etc/inittab
        kill -HUP 1
        ;;
  stop)
        echo "Stopping UDC Gadgets"
        echo "" > $GADGET/UDC

        rm $GADGET/configs/c.1/rndis.0
        rm $GADGET/configs/c.1/mass_storage.0
        rm $GADGET/configs/c.1/acm.usb0

        rmdir $GADGET/strings/0x409
        rmdir $GADGET/configs/c.1/strings/0x409
        rmdir $GADGET/configs/c.1

        #rmdir $GADGET/functions/acm.usb0
        rmdir $GADGET/functions/rndis.0
        rmdir $GADGET/functions/mass_storage.0

        rmdir $GADGET 2> /dev/null
        modprobe configfs -r
        modprobe libcomposite -r
        ;;
  restart|reload)
        "$0" stop
        "$0" start
        ;;
  *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $?
