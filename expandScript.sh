#!/bin/sh

# Based on YunDiskSpaceExpander Sketch
# runs the exact same checks and commands, comment and uncomment lines as you wish
# (partitioning is commented out as I do it by myself usually)


DPS=700 # data partition size on sd card in MB


haltIfSDAlreadyOnOverlay () {
	#mount | grep ^/dev/sda | grep 'on /overlay' # should return empty
	if [[ $(mount | grep ^/dev/sda | grep 'on /overlay') ]]; then
		echo "check not ok: already mounted as overlay"
		exit 1
	else
		echo "check ok: not mounted yet"
	fi
}

haltIfInternalFlashIsFull () {
	if [ $(df / | awk '/rootfs/ {print $4}') -ge 1000 ]; then # should be above 1000
		echo "check ok: more than 1000 bytes available"
	else
		echo "check not ok: not enough disk space"
		exit 1
	fi
}

haltIfSDCardIsNotPresent () {
	ls /mnt/sda1 # should not return 0
	if [ $? -ne "0" ]; then
		echo "check not ok: SD card is not present"
		exit 1
	else
		echo "check ok: SD card is present"
	fi
}

installSoftware () {
	echo "installSoftware"
	opkg update # should return successful exit code
	if [ $? -ne 0 ]; then
		echo "opkg update failed"
		exit 1
	fi
	opkg install e2fsprogs mkdosfs fdisk rsync # should return successful exit code
	if [ $? -ne 0 ]; then
		echo "opkg install failed"
		exit 1
	fi
}


unmount () {
	echo "unmount"
	umount /dev/sda?
	rm -rf /mnt/sda?
}

partitionAndFormatSDCard () {
	echo "partitionAndFormatSDCard"
	unmount

	dd if=/dev/zero of=/dev/sda bs=4096 count=10

	(echo n; echo p; echo 1; echo; echo +${DPS}M; echo w) | fdisk /dev/sda # with [DPS] datapartitionsize

	unmount

	(echo n; echo p; echo 2; echo; echo; echo w) | fdisk /dev/sda

	unmount

	(echo t; echo 1; echo c; echo w) | fdisk /dev/sda

	unmount

	sleep 5

	unmount

	mkfs.vfat /dev/sda1 # should return successful exit code
	if [ $? -ne 0 ]; then
		echo "mkfs.vfat failed"
		exit 1
	fi
}



createArduinoFolder () {
	echo "createArduinoFolder"
	mkdir -p /mnt/sda1
	mount /dev/sda1 /mnt/sda1
	mkdir -p /mnt/sda1/arduino/www

	unmount
}



copySystemFilesFromYunToSD () {
	echo "copySystemFilesFromYunToSD"
	mkdir -p /mnt/sda2
	mount /dev/sda2 /mnt/sda2
	rsync -a --exclude=/mnt/ --exclude=/www/sd /overlay/ /mnt/sda2/

	unmount
}



enableExtRoot () {
	echo "enableExtRoot"
	uci add fstab mount
	uci set fstab.@mount[0].target=/overlay
	uci set fstab.@mount[0].fstype=ext4
	uci set fstab.@mount[0].enabled=1
	uci set fstab.@mount[0].enabled_fsck=0
	uci set fstab.@mount[0].options=rw,sync,noatime,nodiratime
	uci commit
}




haltIfSDAlreadyOnOverlay
    
haltIfInternalFlashIsFull
      
haltIfSDCardIsNotPresent

installSoftware

#partitionAndFormatSDCard
            
createArduinoFolder
              
copySystemFilesFromYunToSD
                
enableExtRoot
                  
echo "finished"
exit 0
                  
                  
