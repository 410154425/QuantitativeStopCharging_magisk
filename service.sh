until [ $(getprop sys.boot_completed) -eq 1 ] ; do
  sleep 5
done
sleep 10
MODDIR=${0%/*}
chmod 0755 "$MODDIR/up"
chmod 0755 "$MODDIR/qsc.sh"
chmod 0755 "$MODDIR/update.sh"
chmod 0755 "$MODDIR/list_search.sh"
chmod 0755 "$MODDIR/testing.sh"
chmod 0755 "$MODDIR/temp.sh"
chmod 0644 "$MODDIR/config.conf"
chmod 0644 "$MODDIR/log.log"
sleep 3
up=1
"$MODDIR/list_search.sh" > /dev/null 2>&1 &
while :;
do
if [ "$up" = "20" -o "$up" = "7200" ]; then
	"$MODDIR/up" > /dev/null 2>&1 &
	up=21
fi
"$MODDIR/qsc.sh" > /dev/null 2>&1
up="$(( $up + 1 ))"
sleep_time="$(cat "$MODDIR/config.conf" | egrep '^sleep_time=' | sed -n 's/sleep_time=//g;$p')"
if [ "$sleep_time" -ge "1" ]; then
	sleep "$sleep_time"
else
	sleep 3
fi
done
