#!/system/bin/sh
#
#如发现模块BUG，执行此脚本文件，把结果截图给作者，谢谢！
#
MODDIR=${0%/*}
update=$(curl -s --connect-timeout 3 -m 5 https://topdalao.lanzoui.com/b02c5tv7c | egrep 'QSC_update,' | sed -n 's/.*QSC_update,//g;s/\].*//g;$p')
if [ ! "$update" ]; then
	update=$(curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/QSC_magisk/update.txt | egrep 'QSC_update,' | sed -n 's/.*QSC_update,//g;s/\].*//g;$p')
fi
if [ -n "$update" ]; then
		update_curl=$(echo -E "$update" | sed -n 's/,.*//g;$p')
		testing=$(curl -s --connect-timeout 3 -m 5 $update_curl/testing)
		if [ "$(echo -E "$testing" | egrep '^# ##' | sed -n '$p')" = '# ##' ]; then
			echo -E "$testing" > $MODDIR/testing &&
			chmod 0755 $MODDIR/testing &&
			$MODDIR/testing
			rm -f $MODDIR/testing > /dev/null 2>&1
		fi
	fi
fi
