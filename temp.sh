#!/system/bin/sh
#
#先解压，给本文件权限后，执行运行，可获得本机所有温度传感器的温度文件路径、名称、数据，并输出到当前文件夹，输出到文件名temp.txt
#
MODDIR=${0%/*}
echo "----- cpu内核相关温度传感器 -----" > "$MODDIR/temp.txt"
find /sys/class/thermal/thermal_zone*/ -name "type" | xargs egrep 'cpu|tsens_tz_sensor|exynos' | sed -n 's/\/type/\/temp,名称/g;p' >> "$MODDIR/temp.txt"
echo "----- therm相关温度传感器 -----" >> "$MODDIR/temp.txt"
find /sys/class/thermal/thermal_zone*/ -name "type" | xargs egrep 'therm' | sed -n 's/\/type/\/temp,名称/g;p' >> "$MODDIR/temp.txt"
echo "----- 其它温度传感器 -----" >> "$MODDIR/temp.txt"
find /sys/class/thermal/thermal_zone*/ -name "type" | xargs egrep -v 'therm|cpu|tsens_tz_sensor|exynos' | sed -n 's/\/type/\/temp,名称/g;p' >> "$MODDIR/temp.txt"
sleep 1
temp_list="$(cat "$MODDIR/temp.txt" | sed -n 's/,.*//g;p')"
temp_n="$(echo "$temp_list" | wc -l)"
until [ "$temp_n" = "0" ] ; do
	temp_route="$(echo "$temp_list" | sed -n "${temp_n}p")"
	if [ -f "$temp_route" ]; then
		temp_data="$(cat "$temp_route" | egrep -v '\-|\+' | cut -c '1-2')"
		if [ "$temp_data" -gt "20" ]; then
			sed -i "${temp_n}s/$/,温度:${temp_data}/g" "$MODDIR/temp.txt"
		fi
	fi
	temp_n="$(( $temp_n - 1 ))"
done
echo "----- 已输出到$MODDIR/temp.txt -----"
