MODDIR=${0%/*}
dumpsys battery reset
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
battery_level="$(dumpsys battery | egrep 'level:' | sed -n 's/.*level: //g;$p')"
battery_powered="$(dumpsys battery | egrep 'powered: true' )"
Shut_down="$(echo "$config_conf" | egrep '^Shut_down=' | sed -n 's/Shut_down=//g;$p')"
battery_current_list="$(echo "$config_conf" | egrep '^battery_current=' | sed -n 's/battery_current=//g;p')"
battery_current_n="$(echo "$battery_current_list" | wc -l)"
charge_current_list="$(cat "$MODDIR/list_charge_current")"
charge_current_n="$(echo "$charge_current_list" | wc -l)"
log_log=0
cpu_log=0
if [ ! -n "$battery_level" ]; then
	exit 0
fi
work_weixin="$(echo "$config_conf" | egrep '^work_weixin=' | sed -n 's/work_weixin=//g;$p')"
if [ "$work_weixin" = "1" ]; then
	Low_battery="$(echo "$config_conf" | egrep '^Low_battery=' | sed -n 's/Low_battery=//g;$p')"
	if [ "$battery_level" -le "$Low_battery" ]; then
		if [ ! -f "$MODDIR/Low_battery" ]; then
			if type curl > /dev/null 2>&1; then
				wx_agentid="$(echo "$config_conf" | egrep '^wx_agentid=' | sed -n 's/wx_agentid=//g;$p')"
				wx_text="$(echo -E "$config_conf" | egrep '^wx_text=' | sed -n 's/wx_text=//g;$p')"
				wx_token="$(cat "$MODDIR/wx_$wx_agentid")"
				wx_url="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$wx_token"
				wx_post="{\"touser\": \"@all\",\"agentid\": \"$wx_agentid\",\"msgtype\": \"text\",\"text\": {\"content\": \"$wx_text\"}}"
				wx_push="$(curl -s --connect-timeout 12 -m 15 -d "$wx_post" "$wx_url")"
				if [ -n "$wx_push" ]; then
					wx_push_errcode="$(echo "$wx_push" | egrep '\"errcode\"' | sed -n 's/ //g;s/.*\"errcode\"://g;s/\".*//g;s/,.*//g;$p')"
					if [ -n "$wx_agentid" ]; then
						if [ "$wx_push_errcode" = "42001" -o "$wx_push_errcode" = "41001" -o "$wx_push_errcode" = "40014" ]; then
							wx_corpid="$(echo "$config_conf" | egrep '^wx_corpid=' | sed -n 's/wx_corpid=//g;$p')"
							wx_secret="$(echo "$config_conf" | egrep '^wx_secret=' | sed -n 's/wx_secret=//g;$p')"
							wx_access_token="$(curl -s --connect-timeout 12 -m 15 "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$wx_corpid&corpsecret=$wx_secret")"
							if [ -n "$wx_access_token" ]; then
								wx_token_errcode="$(echo "$wx_access_token" | egrep '\"errcode\"' | sed -n 's/ //g;s/.*\"errcode\"://g;s/\".*//g;s/,.*//g;$p')"
								if [ "$wx_token_errcode" = "0" ]; then
									wx_token="$(echo "$wx_access_token" | egrep '\"access_token\"' | sed -n 's/ //g;s/.*\"access_token\":\"//g;s/\".*//g;$p')"
									wx_url="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$wx_token"
									wx_post="{\"touser\": \"@all\",\"agentid\": \"$wx_agentid\",\"msgtype\": \"text\",\"text\": {\"content\": \"$wx_text\"}}"
									wx_push="$(curl -s --connect-timeout 12 -m 15 -d "$wx_post" "$wx_url")"
									if [ -n "$wx_push" ]; then
										wx_push_errcode="$(echo "$wx_push" | egrep '\"errcode\"' | sed -n 's/ //g;s/.*\"errcode\"://g;s/\".*//g;s/,.*//g;$p')"
									fi
								else
									echo "$(date +%F_%T) 电量$battery_level 微信消息推送失败：请检查配置参数[企业ID]、[应用Secret]是否填写正确且相互匹配，返回提示：$wx_access_token" >> "$MODDIR/log.log"
								fi
							else
								echo "$(date +%F_%T) 电量$battery_level 微信消息推送失败：网络问题或请求过于频繁遭拦截" >> "$MODDIR/log.log"
							fi
						fi
					else
						echo "$(date +%F_%T) 电量$battery_level 微信消息推送失败：[应用AgentId]参数未填写" >> "$MODDIR/log.log"
					fi
				fi
				if [ -n "$wx_push" ]; then
					if [ "$wx_push_errcode" = "0" ]; then
						echo "$wx_token" > "$MODDIR/wx_$wx_agentid"
						echo "$(date +%F_%T) 电量$battery_level 微信消息推送成功：$wx_text" >> "$MODDIR/log.log"
					elif [ "$wx_push_errcode" = "44004" ]; then
						echo "$(date +%F_%T) 电量$battery_level 微信消息推送失败：[消息内容]参数未填写或填写错误" >> "$MODDIR/log.log"
					elif [ "$wx_push_errcode" != "42001" -a "$wx_push_errcode" != "41001" -a "$wx_push_errcode" != "40014" ]; then
						echo "$(date +%F_%T) 电量$battery_level 微信消息推送失败：请检查配置参数[企业ID]、[应用Secret]、[应用AgentId]是否填写正确且相互匹配，返回提示：$wx_push" >> "$MODDIR/log.log"
					fi
				else
					echo "$(date +%F_%T) 电量$battery_level 微信消息推送失败：网络问题，访问接口失败" >> "$MODDIR/log.log"
				fi
			else
				echo "$(date +%F_%T) 电量$battery_level 缺少curl命令模块：无法使用微信消息推送功能，请安装curl模块后再使用" >> "$MODDIR/log.log"
			fi
			touch "$MODDIR/Low_battery" > /dev/null 2>&1
		fi
	fi
	if [ "$battery_level" -gt "$Low_battery" ]; then
		if [ -f "$MODDIR/Low_battery" ]; then
			rm -f "$MODDIR/Low_battery" > /dev/null 2>&1
		fi
	fi
fi
if [ "$battery_level" -le "$Shut_down" -a "$battery_level" -le "20" ]; then
	reboot -p
fi
if [ -n "$battery_powered" ]; then
	current_now="$(cat '/sys/class/power_supply/battery/current_now')"
	temperature_route="$(echo "$config_conf" | egrep '^temperature_route=' | sed -n 's/temperature_route=//g;$p')"
	if [ ! -f "$temperature_route" ]; then
		temperature_route="$(cat "$MODDIR/list_thermal_zone" | sed -n '1p')"
	fi
	temperature_cpu="$(cat "$temperature_route" | egrep -v '\-|\+' | cut -c '1-2')"
	log_n="$(cat "$MODDIR/log.log" | wc -l)"
	if [ "$log_n" -gt "600" ]; then
		sed -i '1,10d' "$MODDIR/log.log" > /dev/null 2>&1
	fi
	power_stop="$(echo "$config_conf" | egrep '^power_stop=' | sed -n 's/power_stop=//g;$p')"
	temperature_switch="$(echo "$config_conf" | egrep '^temperature_switch=' | sed -n 's/temperature_switch=//g;$p')"
	if [ "$temperature_switch" = "1" ]; then
		temperature_switch_stop="$(echo "$config_conf" | egrep '^temperature_switch_stop=' | sed -n 's/temperature_switch_stop=//g;$p')"
		if [ -n "$temperature_switch_stop" -a "$temperature_cpu" -ge "$temperature_switch_stop" ]; then
			touch "$MODDIR/temperature_switch" > /dev/null 2>&1
			cpu_log=1
		fi
	fi
	if [ -n "$power_stop" -a "$battery_level" -ge "$power_stop" ]; then
		switch_stop_mode=1
	fi
	if [ "$switch_stop_mode" = "1" -o "$cpu_log" = "1" ]; then
		if [ "$cpu_log" = "0" ]; then
			if [ ! -f "$MODDIR/power_switch" ]; then
				power_stop_time="$(echo "$config_conf" | egrep '^power_stop_time=' | sed -n 's/power_stop_time=//g;$p')"
				echo "$(date +%F_%T) 电量$battery_level 停止供电之前 继续供电$power_stop_time秒 倒计时中" >> "$MODDIR/log.log"
				sleep "$power_stop_time"
			fi
		fi
		echo "$(date +%F_%T) 电量$battery_level 电源相关保护 此处固定延时10秒 倒计时中" >> "$MODDIR/log.log"
		sleep 10
		power_switch_list="$(echo "$config_conf" | egrep '^power_switch=' | sed -n 's/power_switch=\[//g;s/\].*//g;p')"
		power_switch_n="$(echo "$power_switch_list" | wc -l)"
		switch_list="$(cat "$MODDIR/list_switch")"
		switch_n="$(echo "$switch_list" | wc -l)"
		until [ "$switch_n" = "0" ] ; do
			power_switch_route="$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/ start=.*//g;$p')"
			if [ -f "$power_switch_route" ]; then
				chmod 0644 "$power_switch_route"
				power_switch_stop="$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/.* stop=//g;$p')"
				echo "$power_switch_stop" > "$power_switch_route"
				log_log=1
			fi
			switch_n="$(( $switch_n - 1 ))"
		done
		until [ "$power_switch_n" = "0" ] ; do
			power_switch_route="$(echo "$power_switch_list" | sed -n "${power_switch_n}p" | sed -n 's/ start=.*//g;$p')"
			if [ -f "$power_switch_route" ]; then
				chmod 0644 "$power_switch_route"
				power_switch_stop="$(echo "$power_switch_list" | sed -n "${power_switch_n}p" | sed -n 's/.* stop=//g;$p')"
				echo "$power_switch_stop" > "$power_switch_route"
				log_log=1
			fi
			power_switch_n="$(( $power_switch_n - 1 ))"
		done
		touch "$MODDIR/power_switch" > /dev/null 2>&1
		if [ "$log_log" = "1" ]; then
			if [ "$cpu_log" = "1" ]; then
				echo "$(date +%F_%T) 电量$battery_level 触发QSC开关温控：停止充电器供电 温度$temperature_cpu" >> "$MODDIR/log.log"
			else
				echo "$(date +%F_%T) 电量$battery_level 停止充电器供电" >> "$MODDIR/log.log"
			fi
		fi
		exit 0
	fi
	if [ -f "$MODDIR/power_switch" ]; then
		rm -f "$MODDIR/power_switch" > /dev/null 2>&1
	fi
	Compatibility_mode="$(echo "$config_conf" | egrep '^Compatibility_mode=' | sed -n 's/Compatibility_mode=//g;$p')"
	if [ "$Compatibility_mode" = "1" ]; then
		exit 0
	fi
	restricted_list="$(echo "$config_conf" | egrep '^restricted=' | sed -n 's/restricted=\[//g;s/\].*//g;p')"
	restricted_n="$(echo "$restricted_list" | wc -l)"
	until [ "$restricted_n" = "0" ] ; do
		restricted_n_route="$(echo "$restricted_list" | sed -n "${restricted_n}p" | sed -n 's/ value=.*//g;$p')"
		if [ -f "$restricted_n_route" ]; then
			chmod 0644 "$restricted_n_route"
			restricted_value="$(echo "$restricted_list" | sed -n "${restricted_n}p" | sed -n 's/.* value=//g;$p')"
			restricted_value1="$(cat "$restricted_n_route")"
			if [ -n "$restricted_value1" -a "$restricted_value1" != "$restricted_value" ]; then
				echo "$restricted_value" > "$restricted_n_route"
			fi
		fi
		restricted_n="$(( $restricted_n - 1 ))"
	done
	battery_stop="$(echo "$config_conf" | egrep '^battery_stop=' | sed -n 's/battery_stop=//g;$p')"
	if [ -n "$battery_stop" -a "$battery_level" -ge "$battery_stop" ]; then
		until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
			if [ "$battery_current_n" != "0" ]; then
				battery_current="$(echo "$battery_current_list" | sed -n "${battery_current_n}p")"
			else
				battery_current="$(echo "$charge_current_list" | sed -n "${charge_current_n}p")"
			fi
			if [ -f "$battery_current" ]; then
				log_log=1
				chmod 0644 "$battery_current"
				battery_current_data1="$(cat "$battery_current" | egrep -v '\-|\+')"
				if [ -n "$battery_current_data1" -a "$battery_current_data1" != "0" ]; then
					battery_current_data2="$(( $battery_current_data1 - 500000 ))"
					if [ "$battery_current_data2" -gt "0" ]; then
						echo "$battery_current_data2" > "$battery_current"
					else
						echo "0" > "$battery_current"
					fi
				fi
			fi
			if [ "$battery_current_n" != "0" ]; then
				battery_current_n="$(( $battery_current_n - 1 ))"
			else
				charge_current_n="$(( $charge_current_n - 1 ))"
			fi
		done
		if [ "$log_log" = "1" ]; then
			echo "$(date +%F_%T) 电量$battery_level 模拟旁路充电：限制电流0 实时电流$current_now 温度$temperature_cpu" >> "$MODDIR/log.log"
		fi
		exit 0
	fi
	battery_stop_1="$(( $battery_stop - 1 ))"
	temperature_current="$(echo "$config_conf" | egrep '^temperature_current=' | sed -n 's/temperature_current=//g;$p')"
	if [ "$temperature_current" = "1" ]; then
		temperature_current_limit="$(echo "$config_conf" | egrep '^temperature_current_limit=' | sed -n 's/temperature_current_limit=//g;$p')"
		default_current_limit="$(echo "$config_conf" | egrep '^default_current_limit=' | sed -n 's/default_current_limit=//g;$p')"
		if [ -n "$temperature_current_limit" -a "$temperature_cpu" -ge "$temperature_current_limit" ]; then
			cpu_log=2
		elif [ -n "$default_current_limit" -a "$temperature_cpu" -ge "$default_current_limit" ]; then
			cpu_log=1
		fi
	fi
	slow_charge="$(echo "$config_conf" | egrep '^slow_charge=' | sed -n 's/slow_charge=//g;$p')"
	if [ -n "$slow_charge" -a "$battery_level" != "$battery_stop_1" -a "$battery_level" -ge "$slow_charge" ]; then
		slow_charge_mode=1
	fi
	if [ "$battery_level" = "$battery_stop_1" -o "$cpu_log" = "2" -o "$slow_charge_mode" = "1" ]; then
		constant_current_max="$(echo "$config_conf" | egrep '^constant_current_max=' | egrep -v '\-|\+' | sed -n 's/constant_current_max=//g;$p')"
		if [ -n "$constant_current_max" ]; then
			until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
				if [ "$battery_current_n" != "0" ]; then
					battery_current="$(echo "$battery_current_list" | sed -n "${battery_current_n}p")"
				else
					battery_current="$(echo "$charge_current_list" | sed -n "${charge_current_n}p")"
				fi
				if [ -f "$battery_current" ]; then
					log_log=1
					chmod 0644 "$battery_current"
					battery_current_data1="$(cat "$battery_current" | egrep -v '\-|\+')"
					if [ -n "$battery_current_data1" -a "$battery_current_data1" != "$constant_current_max" ]; then
						battery_current_data2="$(( $battery_current_data1 - 500000 ))"
						if [ "$battery_current_data2" -gt "$constant_current_max" ]; then
							echo "$battery_current_data2" > "$battery_current"
						else
							echo "$constant_current_max" > "$battery_current"
						fi
					fi
				fi
				if [ "$battery_current_n" != "0" ]; then
					battery_current_n="$(( $battery_current_n - 1 ))"
				else
					charge_current_n="$(( $charge_current_n - 1 ))"
				fi
			done
		fi
		if [ "$log_log" = "1" ]; then
			if [ "$cpu_log" = "2" ]; then
				echo "$(date +%F_%T) 电量$battery_level 触发二限电流温控：限制电流$constant_current_max 实时电流$current_now 温度$temperature_cpu" >> "$MODDIR/log.log"
			elif [ "$slow_charge_mode" = "1" ]; then
				echo "$(date +%F_%T) 电量$battery_level 慢充模式：限制电流$constant_current_max 实时电流$current_now 温度$temperature_cpu" >> "$MODDIR/log.log"
			else
				echo "$(date +%F_%T) 电量$battery_level 模拟旁路充电：限制电流$constant_current_max 实时电流$current_now 温度$temperature_cpu" >> "$MODDIR/log.log"
			fi
		fi
		exit 0
	fi
	if [ "$battery_level" -lt "$battery_stop_1" ]; then
		app_limit="$(echo "$config_conf" | egrep '^app_limit=' | sed -n 's/app_limit=//g;$p')"
		if [ "$app_limit" = "1" ]; then
			app_list="$(echo "$config_conf" | egrep '^app=' | sed -n 's/app=\[//g;s/\].*//g;p')"
			app_n="$(echo "$app_list" | wc -l)"
			until [ "$app_n" = "0" ] ; do
				app_name="$(echo "$app_list" | sed -n "${app_n}p")"
				if [ -n "$app_name" ]; then
					app_ps="$(ps -ef | egrep "$app_name" | egrep -v "${app_name}:" | egrep -v 'egrep')"
					if [ -n "$app_ps" ]; then
						app_current_max="$(echo "$config_conf" | egrep '^app_current_max=' | egrep -v '\-|\+' | sed -n 's/app_current_max=//g;$p')"
						if [ -n "$app_current_max" ]; then
							until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
								if [ "$battery_current_n" != "0" ]; then
									battery_current="$(echo "$battery_current_list" | sed -n "${battery_current_n}p")"
								else
									battery_current="$(echo "$charge_current_list" | sed -n "${charge_current_n}p")"
								fi
								if [ -f "$battery_current" ]; then
									log_log=1
									chmod 0644 "$battery_current"
									battery_current_data1="$(cat "$battery_current" | egrep -v '\-|\+')"
									if [ -n "$battery_current_data1" -a "$battery_current_data1" != "$app_current_max" ]; then
										battery_current_data2="$(( $battery_current_data1 - 500000 ))"
										if [ "$battery_current_data2" -gt "$app_current_max" ]; then
											echo "$battery_current_data2" > "$battery_current"
										else
											echo "$app_current_max" > "$battery_current"
										fi
									fi
								fi
								if [ "$battery_current_n" != "0" ]; then
									battery_current_n="$(( $battery_current_n - 1 ))"
								else
									charge_current_n="$(( $charge_current_n - 1 ))"
								fi
							done
						fi
						if [ "$log_log" = "1" ]; then
							echo "$(date +%F_%T) 电量$battery_level 游戏模式：限制电流$app_current_max 实时电流$current_now 温度$temperature_cpu" >> "$MODDIR/log.log"
						fi
						exit 0
					fi
				fi
				app_n="$(( $app_n - 1 ))"
			done
		fi
		if [ "$cpu_log" = "1" ]; then
			default_current_max="$(echo "$config_conf" | egrep '^default_current_max_limit=' | egrep -v '\-|\+' | sed -n 's/default_current_max_limit=//g;$p')"
		else
			default_current_max="$(echo "$config_conf" | egrep '^default_current_max=' | egrep -v '\-|\+' | sed -n 's/default_current_max=//g;$p')"
		fi
		if [ -n "$default_current_max" ]; then
			until [ "$battery_current_n" = "0" -a "$charge_current_n" = "0" ] ; do
				if [ "$battery_current_n" != "0" ]; then
					battery_current="$(echo "$battery_current_list" | sed -n "${battery_current_n}p")"
				else
					battery_current="$(echo "$charge_current_list" | sed -n "${charge_current_n}p")"
				fi
				if [ -f "$battery_current" ]; then
					log_log=1
					chmod 0644 "$battery_current"
					battery_current_data1="$(cat "$battery_current" | egrep -v '\-|\+')"
					if [ -n "$battery_current_data1" -a "$battery_current_data1" != "$default_current_max" ]; then
						battery_current_data2="$(( $battery_current_data1 - 500000 ))"
						if [ "$battery_current_data2" -gt "$default_current_max" ]; then
							echo "$battery_current_data2" > "$battery_current"
						else
							echo "$default_current_max" > "$battery_current"
						fi
					fi
				fi
				if [ "$battery_current_n" != "0" ]; then
					battery_current_n="$(( $battery_current_n - 1 ))"
				else
					charge_current_n="$(( $charge_current_n - 1 ))"
				fi
			done
		fi
		if [ "$log_log" = "1" ]; then
			if [ "$cpu_log" = "1" ]; then
				echo "$(date +%F_%T) 电量$battery_level 触发一限电流温控：限制电流$default_current_max 实时电流$current_now 温度$temperature_cpu" >> "$MODDIR/log.log"
			else
				echo "$(date +%F_%T) 电量$battery_level 默认模式：限制电流$default_current_max 实时电流$current_now 温度$temperature_cpu" >> "$MODDIR/log.log"
			fi
		fi
		exit 0
	fi
else
	if [ -f "$MODDIR/power_switch" ]; then
		power_start="$(echo "$config_conf" | egrep '^power_start=' | sed -n 's/power_start=//g;$p')"
		if [ "$battery_level" -le "$power_start" -o -f "$MODDIR/temperature_switch" ]; then
			temperature_switch="$(echo "$config_conf" | egrep '^temperature_switch=' | sed -n 's/temperature_switch=//g;$p')"
			if [ "$temperature_switch" = "1" -a -f "$MODDIR/temperature_switch" ]; then
				temperature_route="$(echo "$config_conf" | egrep '^temperature_route=' | sed -n 's/temperature_route=//g;$p')"
				if [ ! -f "$temperature_route" ]; then
					temperature_route="$(cat "$MODDIR/list_thermal_zone" | sed -n '1p')"
				fi
				temperature_cpu="$(cat "$temperature_route" | egrep -v '\-|\+' | cut -c '1-2')"
				temperature_switch_start="$(echo "$config_conf" | egrep '^temperature_switch_start=' | sed -n 's/temperature_switch_start=//g;$p')"
				if [ -n "$temperature_switch_start" -a "$temperature_cpu" -gt "$temperature_switch_start" ]; then
					exit 0
				else
					cpu_log=1
				fi
			fi
			echo "$(date +%F_%T) 电量$battery_level 电源相关保护 此处固定延时10秒 倒计时中" >> "$MODDIR/log.log"
			sleep 10
			power_switch_list="$(echo "$config_conf" | egrep '^power_switch=' | sed -n 's/power_switch=\[//g;s/\].*//g;p')"
			power_switch_n="$(echo "$power_switch_list" | wc -l)"
			switch_list="$(cat "$MODDIR/list_switch")"
			switch_n="$(echo "$switch_list" | wc -l)"
			until [ "$switch_n" = "0" ] ; do
				power_switch_route="$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/ start=.*//g;$p')"
				if [ -f "$power_switch_route" ]; then
					chmod 0644 "$power_switch_route"
					power_switch_start="$(echo "$switch_list" | sed -n "${switch_n}p" | sed -n 's/.* start=//g;s/ stop=.*//g;$p')"
					echo "$power_switch_start" > "$power_switch_route"
					log_log=1
				fi
				switch_n="$(( $switch_n - 1 ))"
			done
			until [ "$power_switch_n" = "0" ] ; do
				power_switch_route="$(echo "$power_switch_list" | sed -n "${power_switch_n}p" | sed -n 's/ start=.*//g;$p')"
				if [ -f "$power_switch_route" ]; then
				chmod 0644 "$power_switch_route"
				power_switch_start="$(echo "$power_switch_list" | sed -n "${power_switch_n}p" | sed -n 's/.* start=//g;s/ stop=.*//g;$p')"
				echo "$power_switch_start" > "$power_switch_route"
				log_log=1
				fi
				power_switch_n="$(( $power_switch_n - 1 ))"
			done
			rm -f "$MODDIR/temperature_switch" > /dev/null 2>&1
			rm -f "$MODDIR/power_switch" > /dev/null 2>&1
			if [ "$log_log" = "1" ]; then
				if [ "$cpu_log" = "1" ]; then
					echo "$(date +%F_%T) 电量$battery_level 触发QSC开关温控：恢复充电器供电 温度$temperature_cpu" >> "$MODDIR/log.log"
				else
					echo "$(date +%F_%T) 电量$battery_level 恢复充电器供电" >> "$MODDIR/log.log"
				fi
			fi
		fi
	fi
fi
#version=2021122800
# ##
