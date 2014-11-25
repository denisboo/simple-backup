#!/bin/bash

# Setup some variables (do not use spaces in these paths):
SOURCE='/srv/samba/share/'
TARGETROOTPATH='/media/backup/samba/share/'
LOG='/var/log/simple-backup.log'
STATUS='/var/log/simple-backup-status.log'
RSYNCSW='-ah'
RSYNCOPT='--stats'

# Simple overrides used only for testing:
if [ "$1" = "TEST" ] || [ "$2" = "TEST" ]
then
	SOURCE='/home/user/test/'
	TARGETROOTPATH='/media/backup/user/test/'
	LOG='/dev/stdout'
	STATUS='/dev/null'
fi
if [ "$1" = "-v" ] || [ "$2" = "-v" ]
then
	RSYNCSW='-avh'
fi

# Start notice:
echo -e "\n`date` *** Backup started" >> $LOG
echo "Backup is underway right now..." >> $STATUS

# Remove a rather old snapshot:
OLD=`date -I -d "66 days ago"`
if [ -d $TARGETROOTPATH$OLD ]
then
	echo "Would remove old snapshot $TARGETROOTPATH$OLD" >> $LOG
	# rm -rf $TARGETROOTPATH$OLD >> $LOG
else
	echo "Old snapshot $TARGETROOTPATH$OLD not found" >> $LOG
fi

# Target directory:
mkdir -p $TARGETROOTPATH
DATE=`date -I`
TARGET="$TARGETROOTPATH$DATE/"

# Up to four reference directories for linking against
REFS=($(ls -1 $TARGETROOTPATH | sort -r | grep -P "^\d{4}\-\d{2}\-\d{2}$" | grep -v $DATE | head -4))
for R in ${REFS[@]}
do
	RSYNCOPT+=" --link-dest=$TARGETROOTPATH$R"
done

# Execute the backup:
echo "Rsyncing $SOURCE to $TARGET" >> $LOG
rsync $RSYNCSW $RSYNCOPT $SOURCE $TARGET | sed '/^$/d' >> $LOG
ERR=$?

# Was it ok?
if [ $ERR -eq 0 ]
then
	echo "Last good backup finished on `date`." > $STATUS
else
	echo "Last backup resulted with an ERROR $ERR on `date`." > $STATUS
fi
echo "Check $LOG for details." >> $STATUS

# End notice:
echo "`date` *** Backup finished" >> $LOG
