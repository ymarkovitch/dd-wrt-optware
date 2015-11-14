#!/bin/sh

#this file should have no imports, as it is loaded both before and after remounts

jffs_mount_opt(){
	mount --bind -n /opt/jffs /jffs
}

tmp_jffs_close(){
	#lazy unmount is alright, since tmp jffs is only used in import scripts
	umount -l /jffs
	rm -rf /tmp/jffs
}

tmp_jffs_init_shutdown(){
	mkdir /tmp/jffs
	mount --bind -n /tmp/jffs /jffs
	mkdir -p /jffs/etc/config
	cp -r /opt/jffs/etc/config/shutdown /jffs/etc/config/shutdown
	cp -r /opt/jffs/etc/config/lib /jffs/etc/config/lib
}
