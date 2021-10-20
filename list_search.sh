MODDIR=${0%/*}
find /sys/ -name "input_suspend" -o -name "*disable*_charge*" -o -name "*charge*_disable*" -o -name "*disable*_charging*" -o -name "*stop_charge*" -o -name "*stop_charging*" | egrep -i -v 'limit|max|float|step|reverse' | sed -n 's/$/ start=0 stop=1/g;p' > $MODDIR/list_switch
find /sys/ -name "*charging_enable*" -o -name "*Charging_Enable*" -o -name "*enable*_charge*" -o -name "*charge*_enable*" -o -name "*enable*_charging*" -o -name "*charge*_control*" -o -name "*charging*_state*" | egrep -i -v 'limit|prohibit|prevent|disable|stop|restrict|reverse|max|float|step' | sed -n 's/$/ start=1 stop=0/g;p' >> $MODDIR/list_switch
find /sys/ -name "*charging_enable*" -o -name "*Charging_Enable*" -o -name "*enable*_charge*" -o -name "*charge*_enable*" -o -name "*enable*_charging*" -o -name "*charge*_control*" | egrep -i 'prohibit|prevent|disable|stop|restrict' | egrep -i -v 'limit|max|float|step|reverse' | sed -n 's/$/ start=0 stop=1/g;p' >> $MODDIR/list_switch
find /sys/class/power_supply/main/ -name "*current_max*" | egrep -i -v 'now' | sed -n 's/$/ start=8000000 stop=0/g;p' >> $MODDIR/list_switch
find /sys/ -name "*restrict*_cur*" | egrep -i -v 'usb' > $MODDIR/list_charge_current
find /sys/class/thermal/thermal_zone*/ -name "type" | xargs egrep 'battery' | sed -n 's/\/type.*/\/temp/g;p' > $MODDIR/list_thermal_zone
thermal_zone_list=$(cat "$MODDIR/list_thermal_zone")
if [ ! "$thermal_zone_list" ]; then
	find /sys/class/thermal/thermal_zone*/ -name "type" | xargs egrep 'therm' | sed -n 's/\/type.*/\/temp/g;p' > $MODDIR/list_thermal_zone
	thermal_zone_list=$(cat "$MODDIR/list_thermal_zone")
fi
thermal_zone_n=$(echo "$thermal_zone_list" | wc -l)
temperature_cpu=20
until [ "$thermal_zone_n" = "0" ] ; do
	temperature_route=$(echo "$thermal_zone_list" | sed -n "${thermal_zone_n}p")
	if [ -f "$temperature_route" ]; then
		thermal_zone_data=$(cat "$temperature_route" | egrep -v '\-|\+' | cut -c '1-2')
		if [ "$thermal_zone_data" -gt "$temperature_cpu" ]; then
			temperature_cpu=$thermal_zone_data
			temperature_cpu_route=$temperature_route
		fi
	fi
	thermal_zone_n=$(( $thermal_zone_n - 1 ))
done
echo "$temperature_cpu_route" > $MODDIR/list_thermal_zone
# ##
