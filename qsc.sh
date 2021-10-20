MODDIR=${0%/*}
dumpsys battery reset
config_conf=$(cat "$MODDIR/config.conf" | egrep -v '^#')
battery_level=$(dumpsys battery | egrep 'level:' | sed -n 's/.*level: //g;$p')
battery_powered=$(dumpsys battery | egrep 'powered: true' )
Shut_down=$(echo "$config_conf" | egrep '^Shut_down=' | sed -n 's/.*=//g;$p')
battery_current_list=$(echo "$config_conf" | egrep '^battery_current=' | sed -n 's/.*=//g;p')
battery_current_n=$(echo "$battery_current_list" | wc -l)
charge_current_list=$(cat "$MODDIR/list_charge_current")
charge_current_n=$(echo "$charge_current_list" | wc -l)
log_log=0
cpu_log=0
if [ "$battery_level" -le "$Shut_down" -a "$battery_level" -le "20" ]; then
	reboot -p
fi
if [ -n "$battery_powered" ]; then
	current_now=$(cat '/sys/class/power_supply/battery/current_now')
	temperature_route=$(echo "$config_conf" | egrep '^temperature_route=' | sed -n 's/.*=//g;$p')
	if [ ! -f "$temperature_route" ]; then
		temperature_route=$(cat "$MODDIR/list_thermal_zone" | sed -n '1p')
	fi
	temperature_cpu=$(cat "$temperature_route" | egrep -v '\-|\+' | cut -c '1-2')
	log_n=$(cat $MODDIR/log.log | wc -l)
	if [ "$log_n" -gt "600" ]; then
		sed -i '1,10d' $MODDIR/log.log > /dev/null 2>&1
	fi
	power_stop=$(echo "$config_conf" | egrep '^power_stop=' | sed -n 's/.*=//g;$p')
	temperature_switch=$(echo "$config_conf" | egrep '^temperature_switch=' | sed -n 's/.*=//g;$p')
	if [ "$temperature_switch" = "1" ]; then
		temperature_switch_stop=$(echo "$config_conf" | egrep '^temperature_switch_stop=' | sed -n 's/.*=//g;$p')
		if [ "$temperature_cpu" -ge "$temperature_switch_stop" ]; then
			battery_level=$power_stop
			touch $MODDIR/temperature_switch > /dev/null 2>&1
			cpu_log=1
		fi
	fi
	if [ "$battery_level" -ge "$power_stop" ]; then
		if [ "$cpu_log" = "0" ]; then
			if [ ! -f "$MODDIR/power_switch" ]; then
				power_stop_time=$(echo "$config_conf" | egrep '^power_stop_time=' | sed -n 's/.*=//g;$p')
				echo "$(date +%T) 电量$battery_level 停止供电之前 继续供电$power_stop_time秒 倒计时中" >> $MODDIR/log.log
				sleep $power_stop_time
			fi
		fi
		power_switch_list=$(echo "$config_conf" | egrep '^power_switch=' | sed -n 's/.*=\[//g;s/\].*//g;p')
		power_switch_n=$(echo "$power_switch_list" | wc -l)
		switch_list=$(cat "$MODDIR/list_switch")
		switch_n=$(echo "$switch_list" | wc -l)
		until [ "$switch_n" = "0" ] ; do
			power_switch_route=$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/ start=.*//g;$p')
			if [ -f "$power_switch_route" ]; then
				chmod 0644 $power_switch_route
				power_switch_stop=$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/.*stop=//g;$p')
				echo "$power_switch_stop" > $power_switch_route
				log_log=1
			fi
			switch_n=$(( $switch_n - 1 ))
		done
		until [ "$power_switch_n" = "0" ] ; do
			power_switch_route=$(echo "$power_switch_list" | sed -n "${power_switch_n}p" | sed -n 's/ start=.*//g;$p')
			if [ -f "$power_switch_route" ]; then
				chmod 0644 $power_switch_route
				power_switch_stop=$(echo "$power_switch_list" | sed -n "${power_switch_n}p" | sed -n 's/.*stop=//g;$p')
				echo "$power_switch_stop" > $power_switch_route
				log_log=1
			fi
			power_switch_n=$(( $power_switch_n - 1 ))
		done
		until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
			if [ "$battery_current_n" != "0" ]; then
				battery_current=$(echo "$battery_current_list" | sed -n "${battery_current_n}p")
			else
				battery_current=$(echo "$charge_current_list" | sed -n "${charge_current_n}p")
			fi
			if [ -f "$battery_current" ]; then
				chmod 0644 $battery_current
				echo "0" > $battery_current
			fi
			if [ "$battery_current_n" != "0" ]; then
				battery_current_n=$(( $battery_current_n - 1 ))
			else
				charge_current_n=$(( $charge_current_n - 1 ))
			fi
		done
		touch $MODDIR/power_switch > /dev/null 2>&1
		if [ "$log_log" = "1" ]; then
			if [ "$cpu_log" = "1" ]; then
				echo "$(date +%T) 温度$temperature_cpu 触发QSC开关温控：停止充电器供电" >> $MODDIR/log.log
			else
				echo "$(date +%T) 电量$battery_level 停止充电器供电" >> $MODDIR/log.log
			fi
		fi
		exit 0
	fi
	if [ -f "$MODDIR/power_switch" ]; then
		rm -f $MODDIR/power_switch > /dev/null 2>&1
	fi
	restricted_list=$(echo "$config_conf" | egrep '^restricted=' | sed -n 's/.*=\[//g;s/\].*//g;p')
	restricted_n=$(echo "$restricted_list" | wc -l)
	until [ "$restricted_n" = "0" ] ; do
		restricted_n_route=$(echo "$restricted_list" | sed -n "${restricted_n}p" | sed -n 's/ value=.*//g;$p')
		if [ -f "$restricted_n_route" ]; then
			chmod 0644 $restricted_n_route
			restricted_value=$(echo "$restricted_list" | sed -n "${restricted_n}p" | sed -n 's/.*value=//g;$p')
			echo "$restricted_value" > $restricted_n_route
		fi
		restricted_n=$(( $restricted_n - 1 ))
	done
	battery_stop=$(echo "$config_conf" | egrep '^battery_stop=' | sed -n 's/.*=//g;$p')
	if [ "$battery_level" -ge "$battery_stop" ]; then
		until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
			if [ "$battery_current_n" != "0" ]; then
				battery_current=$(echo "$battery_current_list" | sed -n "${battery_current_n}p")
			else
				battery_current=$(echo "$charge_current_list" | sed -n "${charge_current_n}p")
			fi
			if [ -f "$battery_current" ]; then
				chmod 0644 $battery_current
				echo "0" > $battery_current
				log_log=1
			fi
			if [ "$battery_current_n" != "0" ]; then
				battery_current_n=$(( $battery_current_n - 1 ))
			else
				charge_current_n=$(( $charge_current_n - 1 ))
			fi
		done
		if [ "$log_log" = "1" ]; then
			echo "$(date +%T) 电量$battery_level 模拟旁路充电：限制电流0 实时电流$current_now 温度$temperature_cpu" >> $MODDIR/log.log

		fi
		exit 0
	fi
	battery_stop_1=$(( $battery_stop - 1 ))
	temperature_current=$(echo "$config_conf" | egrep '^temperature_current=' | sed -n 's/.*=//g;$p')
	if [ "$temperature_current" = "1" ]; then
		temperature_current_limit=$(echo "$config_conf" | egrep '^temperature_current_limit=' | sed -n 's/.*=//g;$p')
		if [ "$temperature_cpu" -ge "$temperature_current_limit" ]; then
			battery_level=$battery_stop_1
			cpu_log=1
		fi
	fi
	constant_current_max=$(echo "$config_conf" | egrep '^constant_current_max=' | sed -n 's/.*=//g;$p')
	if [ "$battery_level" = "$battery_stop_1" ]; then
		until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
			if [ "$battery_current_n" != "0" ]; then
				battery_current=$(echo "$battery_current_list" | sed -n "${battery_current_n}p")
			else
				battery_current=$(echo "$charge_current_list" | sed -n "${charge_current_n}p")
			fi
			if [ -f "$battery_current" ]; then
				chmod 0644 $battery_current
				echo "$constant_current_max" > $battery_current
				log_log=1
			fi
			if [ "$battery_current_n" != "0" ]; then
				battery_current_n=$(( $battery_current_n - 1 ))
			else
				charge_current_n=$(( $charge_current_n - 1 ))
			fi
		done
		if [ "$log_log" = "1" ]; then
			if [ "$cpu_log" = "1" ]; then
				echo "$(date +%T) 温度$temperature_cpu 触发电流温控：限制电流$constant_current_max 实时电流$current_now" >> $MODDIR/log.log
			else
				echo "$(date +%T) 电量$battery_level 模拟旁路充电：限制电流$constant_current_max 实时电流$current_now 温度$temperature_cpu" >> $MODDIR/log.log
			fi
		fi
		exit 0
	fi
	if [ "$battery_level" -lt "$battery_stop_1" ]; then
		app_limit=$(echo "$config_conf" | egrep '^app_limit=' | sed -n 's/.*=//g;$p')
		if [ "$app_limit" = "1" ]; then
			app_list=$(echo "$config_conf" | egrep '^app=' | sed -n 's/.*=\[//g;s/\].*//g;p')
			app_n=$(echo "$app_list" | wc -l)
			until [ "$app_n" = "0" ] ; do
				app_name=$(echo "$app_list" | sed -n "${app_n}p")
				if [ -n "$app_name" ]; then
					app_ps=$(ps -ef | egrep "$app_name" | egrep -v "${app_name}:" | egrep -v 'egrep')
					if [ -n "$app_ps" ]; then
						app_current_max=$(echo "$config_conf" | egrep '^app_current_max=' | sed -n 's/.*=//g;$p')
						until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
							if [ "$battery_current_n" != "0" ]; then
								battery_current=$(echo "$battery_current_list" | sed -n "${battery_current_n}p")
							else
								battery_current=$(echo "$charge_current_list" | sed -n "${charge_current_n}p")
							fi
							if [ -f "$battery_current" ]; then
								chmod 0644 $battery_current
								echo "$app_current_max" > $battery_current
								log_log=1
							fi
							if [ "$battery_current_n" != "0" ]; then
								battery_current_n=$(( $battery_current_n - 1 ))
							else
								charge_current_n=$(( $charge_current_n - 1 ))
							fi
						done
						if [ "$log_log" = "1" ]; then
							echo "$(date +%T) 电量$battery_level 游戏模式：限制电流$app_current_max 实时电流$current_now 温度$temperature_cpu" >> $MODDIR/log.log
						fi
						exit 0
					fi
				fi
				app_n=$(( $app_n - 1 ))
			done
		fi
		default_current_max=$(echo "$config_conf" | egrep '^default_current_max=' | sed -n 's/.*=//g;$p')
		until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
			if [ "$battery_current_n" != "0" ]; then
				battery_current=$(echo "$battery_current_list" | sed -n "${battery_current_n}p")
			else
				battery_current=$(echo "$charge_current_list" | sed -n "${charge_current_n}p")
			fi
			if [ -f "$battery_current" ]; then
				chmod 0644 $battery_current
				echo "$default_current_max" > $battery_current
				log_log=1
			fi
			if [ "$battery_current_n" != "0" ]; then
				battery_current_n=$(( $battery_current_n - 1 ))
			else
				charge_current_n=$(( $charge_current_n - 1 ))
			fi
		done
		if [ "$log_log" = "1" ]; then
			echo "$(date +%T) 电量$battery_level 默认模式：限制电流$default_current_max 实时电流$current_now 温度$temperature_cpu" >> $MODDIR/log.log
		fi
		exit 0
	fi
else
	if [ -f "$MODDIR/power_switch" ]; then
		power_start=$(echo "$config_conf" | egrep '^power_start=' | sed -n 's/.*=//g;$p')
		if [ "$battery_level" -le "$power_start" -o -f "$MODDIR/temperature_switch" ]; then
			temperature_switch=$(echo "$config_conf" | egrep '^temperature_switch=' | sed -n 's/.*=//g;$p')
			if [ "$temperature_switch" = "1" -a -f "$MODDIR/temperature_switch" ]; then
				temperature_route=$(echo "$config_conf" | egrep '^temperature_route=' | sed -n 's/.*=//g;$p')
				if [ ! -f "$temperature_route" ]; then
					temperature_route=$(cat "$MODDIR/list_thermal_zone" | sed -n '1p')
				fi
				temperature_cpu=$(cat "$temperature_route" | egrep -v '\-|\+' | cut -c '1-2')
				temperature_switch_start=$(echo "$config_conf" | egrep '^temperature_switch_start=' | sed -n 's/.*=//g;$p')
				if [ "$temperature_cpu" -gt "$temperature_switch_start" ]; then
					exit 0
				else
					cpu_log=1
				fi
			fi
			power_switch_list=$(echo "$config_conf" | egrep '^power_switch=' | sed -n 's/.*=\[//g;s/\].*//g;p')
			power_switch_n=$(echo "$power_switch_list" | wc -l)
			switch_list=$(cat "$MODDIR/list_switch")
			switch_n=$(echo "$switch_list" | wc -l)
			until [ "$switch_n" = "0" ] ; do
				power_switch_route=$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/ start=.*//g;$p')
				if [ -f "$power_switch_route" ]; then
					chmod 0644 $power_switch_route
					power_switch_start=$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/.*start=//g;s/ stop=.*//g;$p')
					echo "$power_switch_start" > $power_switch_route
					log_log=1
				fi
				switch_n=$(( $switch_n - 1 ))
			done
			until [ "$power_switch_n" = "0" ] ; do
				power_switch_route=$(echo "$power_switch_list" | sed -n "${power_switch_n}p" | sed -n 's/ start=.*//g;$p')
				if [ -f "$power_switch_route" ]; then
				chmod 0644 $power_switch_route
				power_switch_start=$(echo "$power_switch_list" | sed -n "${power_switch_n}p" | sed -n 's/.*start=//g;s/ stop=.*//g;$p')
				echo "$power_switch_start" > $power_switch_route
				log_log=1
				fi
				power_switch_n=$(( $power_switch_n - 1 ))
			done
			default_current_max=$(echo "$config_conf" | egrep '^default_current_max=' | sed -n 's/.*=//g;$p')
			until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
				if [ "$battery_current_n" != "0" ]; then
					battery_current=$(echo "$battery_current_list" | sed -n "${battery_current_n}p")
				else
					battery_current=$(echo "$charge_current_list" | sed -n "${charge_current_n}p")
				fi
				if [ -f "$battery_current" ]; then
					chmod 0644 $battery_current
					echo "$default_current_max" > $battery_current
				fi
				if [ "$battery_current_n" != "0" ]; then
					battery_current_n=$(( $battery_current_n - 1 ))
				else
					charge_current_n=$(( $charge_current_n - 1 ))
				fi
			done
			rm -f $MODDIR/temperature_switch > /dev/null 2>&1
			rm -f $MODDIR/power_switch > /dev/null 2>&1
			if [ "$log_log" = "1" ]; then
				if [ "$cpu_log" = "1" ]; then
					echo "$(date +%T) 温度$temperature_cpu 触发QSC开关温控：恢复充电器供电" >> $MODDIR/log.log
				else
					echo "$(date +%T) 电量$battery_level 恢复充电器供电" >> $MODDIR/log.log
				fi
			fi
			exit 0
		fi
	fi
fi
#version=2021102000
# ##
