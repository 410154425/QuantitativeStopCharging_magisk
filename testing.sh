#!/system/bin/sh
#
#如发现模块BUG，执行此脚本文件，把结果截图给作者，谢谢！
#
MODDIR=${0%/*}
#----------
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
#----------
echo ---------- 充电状态 ------------
dumpsys battery
#----------
echo ---------- 充电开关 ------------
switch_list="$(cat "$MODDIR/list_switch")"
switch_n="$(echo "$switch_list" | wc -l)"
until [ "$switch_n" = "0" ] ; do
	power_switch_route="$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/ start=.*//g;$p')"
	if [ -f "$power_switch_route" ]; then
		power_switch_data1="$power_switch_route,$(cat "$power_switch_route"),$power_switch_data1"
	fi
	switch_n="$(( $switch_n - 1 ))"
done
switch_list="$(echo "$config_conf" | egrep '^power_switch=' | sed -n 's/.*=\[//g;s/ start=.*//g;p')"
switch_n="$(echo "$switch_list" | wc -l)"
until [ "$switch_n" = "0" ] ; do
	power_switch_route="$(echo "$switch_list" | sed -n "${switch_n}p")"
	if [ -f "$power_switch_route" ]; then
		power_switch_data2="$power_switch_route,$(cat "$power_switch_route"),$power_switch_data2"
	fi
	switch_n="$(( $switch_n - 1 ))"
done
echo "检索开关.$power_switch_data1,自定义开关.$power_switch_data2"
#----------
echo ---------- 电流文件 ------------
battery_current_list="$(cat "$MODDIR/list_charge_current")"
battery_current_n="$(echo "$battery_current_list" | wc -l)"
until [ "$battery_current_n" = "0" ] ; do
	battery_current="$(echo "$battery_current_list" | sed -n "${battery_current_n}p")"
	if [ -f "$battery_current" ]; then
		battery_current_data1="$battery_current,$(cat "$battery_current"),$battery_current_data1"
	fi
	battery_current_n="$(( $battery_current_n - 1 ))"
done
battery_current_list="$(echo "$config_conf" | egrep '^battery_current=')"
battery_current_n="$(echo "$battery_current_list" | wc -l)"
until [ "$battery_current_n" = "0" ] ; do
	battery_current="$(echo "$battery_current_list" | sed -n "${battery_current_n}p" | sed -n 's/.*=//g;p')"
	if [ -f "$battery_current" ]; then
		battery_current_data2="$battery_current,$(cat "$battery_current"),$battery_current_data2"
	fi
	battery_current_n="$(( $battery_current_n - 1 ))"
done
echo "检索电流文件.$battery_current_data1,自定义电流文件.$battery_current_data2"
#----------
echo ---------- 机型 ------------
module_version="$(cat "$MODDIR/module.prop" | grep 'version=' | sed -n 's/.*version\=//g;$p')"
Host_version="$(cat "$MODDIR/qsc.sh" | egrep '^#version=' | sed -n 's/.*version=//g;$p')"
echo "module.$(echo $module_version | sed -n 's/ //g;$p'),version.$(echo $Host_version | sed -n 's/ //g;$p'),serialno.$(getprop ro.serialno | sed -n 's/ //g;$p'),release.$(getprop ro.build.version.release | sed -n 's/ //g;$p'),sdk.$(getprop ro.build.version.sdk | sed -n 's/ //g;$p'),brand.$(getprop ro.product.brand | sed -n 's/ //g;$p'),model.$(getprop ro.product.model | sed -n 's/ //g;$p'),cpu.$(cat '/proc/cpuinfo' | egrep 'Hardware' | sed -n 's/.*://g;s/ //g;$p')"
# ##
