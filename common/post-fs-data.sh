#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode

# Delete and disable system logs on dropbox
rm /data/system/dropbox/*
rm /data/system/usagestats/daily/*
rm /data/system/usagestats/0/monthly/*
rm /data/system/usagestats/0/weekly/*
rm /data/system/usagestats/0/yearly*
chmod 000 /data/system/default_values
chmod 400 /data/system/dropbox
chmod 400 /data/system/usagestats/0/daily
chmod 400 /data/system/usagestats/0/monthly
chmod 400 /data/system/usagestats/0/weekly
chmod 400 /data/system/usagestats/0/yearly

# Zipalign
LOG_FILE=/data/droid84-align.log;
ZIPALIGNDB=/data/droid84-align.db;

if [ -e $LOG_FILE ]; then
	rm $LOG_FILE;
fi;

if [ ! -f $ZIPALIGNDB ]; then
	touch $ZIPALIGNDB;
fi;

busybox mount -o rw,remount /system;

echo "Starting FV Automatic ZipAlign $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $LOG_FILE

for DIR in /data/app /system/app /system/priv-app
do
	cd $DIR;
	for APK in *.apk */*.apk
	do
    if [ $APK -ot $ZIPALIGNDB ] && [ $(grep "$DIR/$APK" $ZIPALIGNDB|wc -l) -gt 0 ] ; then
      echo "Already checked: $DIR/$APK" | tee -a $LOG_FILE
    else
      zipalign -c 4 $APK
      if [ $? -eq 0 ] ; then
        echo "Already aligned: $DIR/$APK" | tee -a $LOG_FILE
        grep "$DIR/$APK" $ZIPALIGNDB > /dev/null || echo $DIR/$APK >> $ZIPALIGNDB
      else
        echo "Now aligning: $DIR/$APK" | tee -a $LOG_FILE
        zipalign -f 4 $APK /cache/$APK
        busybox mount -o rw,remount /system
        cp -f -p /cache/$APK $APK
        busybox rm -f /cache/$APK
        grep "$DIR/$APK" $ZIPALIGNDB > /dev/null || echo $DIR/$APK >> $ZIPALIGNDB
      fi
    fi
  done
done

busybox mount -o ro,remount /system;
touch $ZIPALIGNDB;
echo "Automatic ZipAlign finished at $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $LOG_FILE;
