#! /bin/sh
#
# /etc/init.d/shifter_prep
#

### BEGIN INIT INFO
# Provides:       shifter_prep
# Required-Start: $network $remote_fs
# Required-Stop: $network $remote_fs
# Default-Start:  2 3 5
# Default-Stop:
# Short-Description:    pre-setup node for running shifter
# Description:          pre-setup node for running shifter
### END INIT INFO

SHIFTER_KMOD_DIR=/opt/shifter/udiRoot/kmod/$(uname -r)
INSMOD=/sbin/insmod
RMMOD=/sbin/rmmod

MAX_LOOP=128
test -d $SHIFTER_KMOD_DIR || exit 5

# Shell functions sourced from /etc/rc.status:
#      rc_check         check and set local and overall rc status
#      rc_status        check and set local and overall rc status
#      rc_status -v     ditto but be verbose in local rc status
#      rc_status -v -r  ditto and clear the local rc status
#      rc_failed        set local and overall rc status to failed
#      rc_failed <num>  set local and overall rc status to <num><num>
#      rc_reset         clear local rc status (overall remains)
#      rc_exit          exit appropriate to overall rc status
. /etc/rc.status

# First reset status of this service
rc_reset

# Return values acc. to LSB for all commands but status:
# 0 - success
# 1 - generic or unspecified error
# 2 - invalid or excess argument(s)
# 3 - unimplemented feature (e.ga "reload")
# 4 - insufficient privilege
# 5 - program is not installed
# 6 - program is not configured
# 7 - program is not running
#
# Note that starting an already running service, stopping
# or restarting a not-running service as well as the restart
# with force-reload (in case signalling is not supported) are
# considered a success.

case "$1" in
    start)
    echo -n "Starting shifter prep work"
    ## Start daemon with startproc(8). If this fails
    ## the echo return value is set appropriate.

        $INSMOD $SHIFTER_KMOD_DIR/drivers/block/loop.ko max_loop=$MAX_LOOP
        $INSMOD $SHIFTER_KMOD_DIR/fs/squashfs/squashfs.ko
        $INSMOD $SHIFTER_KMOD_DIR/fs/exportfs/exportfs.ko
        $INSMOD $SHIFTER_KMOD_DIR/fs/xfs/xfs.ko
        $INSMOD $SHIFTER_KMOD_DIR/fs/mbcache.ko
        $INSMOD $SHIFTER_KMOD_DIR/fs/jbd2/jbd2.ko
        $INSMOD $SHIFTER_KMOD_DIR/fs/ext4/ext4.ko

    # Remember status and be verbose
    rc_status -v
    ;;
    stop)
    echo -n "Removing shifter prep work"
    ## Stop daemon with killproc(8) and if this fails
    ## set echo the echo return value.

    $RMMOD loop.ko
    $RMMOD ext4.ko
        $RMMOD jbd2.ko
        $RMMOD mbcache.ko
        $RMMOD xfs.ko
        $RMMOD exportfs.ko
        $RMMOD squashfs.ko

    # Remember status and be verbose
    rc_status -v
    ;;
    try-restart)
    ## Stop the service and if this succeeds (i.e. the
    ## service was running before), start it again.
    ## Note: try-restart is not (yet) part of LSB (as of 0.7.5)
    $0 status >/dev/null &&  $0 restart

    # Remember status and be quiet
    rc_status
    ;;
    restart)
    ## Stop the service and regardless of whether it was
    ## running or not, start it again.
    $0 stop
    $0 start

    # Remember status and be quiet
    rc_status
    ;;
    status)
    echo -n "Checking if shifter already prepped"
    ## Check status with checkproc(8), if process is running
    ## checkproc will return with exit status 0.

    # Status has a slightly different for the status command:
    # 0 - service running
    # 1 - service dead, but /var/run/  pid  file exists
    # 2 - service dead, but /var/lock/ lock file exists
    # 3 - service not running

    # NOTE: checkproc returns LSB compliant status values.
    gotit=$(ls /dev/loop0)
        if [[ -z "$gotit" ]]; then exit 3; fi
        exit 0

    ;;
    *)
    echo "Usage: $0 {start|stop|status|try-restart|restart"
    exit 1
    ;;
esac
rc_exit
