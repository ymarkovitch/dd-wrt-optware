#!/bin/sh

rtrim_n() awk '{printf("%s",$0);}'

$
# Sleep forever with a negative argument
#
sleepf() { [ $((${1:-0})) -ge 0 ] && sleep ${1:-0} || tail -f /dev/null ; }

is_mounted() { cut -d ' ' -f${2:-1} /proc/mounts | grep -qsE "^$1$" ; }

is_mounted_dev() is_mounted "$1" 1

is_mounted_path() is_mounted "$1" 2

#asus RT-N16 specific
GPIO_LED=1
GPIO_WPS_BUTTON=8

led_on() gpio disable $GPIO_LED

led_off() gpio enable $GPIO_LED

# Args: count usec_off usec_on
# Set count to -1 to flash forever
flash_led()
{
    local counter=$1
    while [ $((counter--)) -ne 0 ]
    do
        # Flash off first, as the power light is on by default
        led_off && usleep $2 && led_on && usleep ${3:-$2}
    done
}

chsh_simple()
{
    local homedir usershell

    while getopts ":h:s:u:" flag; do
        case "$flag" in
            h) homedir=$OPTARG;;
            s) usershell=$OPTARG;;
            u) username=$OPTARG;;
            \?)
                echo "illegal option: -$OPTARG" >&2
                exit 1
                ;;
        esac
    done

    if [ -z $username ]; then
        echo "username not specified" >&2
        exit 1
    fi

    #/etc/passwd is linked to /tmp/etc/passwd
    local passwdPath="/tmp/etc/passwd"
    local passwdTmpPath="/tmp/etc/passwd_copy"
    local delim=":"
    while read -r line; do
        if echo $line | grep -q "^$username:"; then
            #sh doesn't have array support
            echo $line | cut -d$delim -f1-5 | rtrim_n
            echo -n $delim

            if [ ! -z $homedir ]; then
                echo -n $homedir
            else
                echo $line | cut -d$delim -f6 | rtrim_n
            fi
            echo -n $delim

            if [ ! -z $usershell ]; then
                echo -n $usershell
            else
                echo $line | cut -d$delim -f7 | rtrim_n
            fi
            echo
        else
            echo $line
        fi 1>>$passwdTmpPath
    done <$passwdPath
    mv $passwdTmpPath $passwdPath
}

unmount_wait()
{
    local retry_num=$1; shift
    local wait_time=$1; shift
    n=1
    local last
    for last; do true; done
    while is_mounted $last; do
        echo "umount $@"
        #use the busybox version in-case opt is to be unmounted
        /bin/umount $@ && return 0
        [ $n -ge $retry_num ] && return 1
        sleep $wait_time
        let n+=1
    done
}

mount_wait()
{
    n=1
    for last; do true; done
    while [ ! -d $last/lost+found ] ; do
	(mount $@) && return 0
	[ $n -gt 45 ] && return 1
	sleep 3
	let n+=1
    done
}
