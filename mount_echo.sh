'logger -t --- '"'"'Mounting USB'"'"'
insmod mbcache
insmod ext2
mkdir /tmp/mnt
mountwait(){
 n=1
 for last; do true; done
 while [ ! -d $last/lost+found ] ; do
  (mount $@) && return 0
  [ $n -gt 45 ] && return 1
  sleep 3
  let n+=1
 done
}
(mountwait -o noatime -n /dev/discs/disc0/part3 /mnt) || logger -t --- '"'"'ERROR Mounting /mnt'"'"'
(mountwait -o noatime -n /dev/discs/disc0/part1 /opt) || logger -t --- '"'"'ERROR Mounting /opt'"'"'
/opt/jffs/etc/config/usb.startup &'