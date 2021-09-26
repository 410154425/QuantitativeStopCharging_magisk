MODDIR=${0%/*}
Host_version=$(cat $MODDIR/qsc.sh | egrep '^#version=' | sed -n 's/.*version=//g;$p')
update_curl="http://z23r562938.iask.in/QSC_magisk"
up1=$(curl -s --connect-timeout 3 -m 5 $update_curl/module.prop)
up2=$(curl -s --connect-timeout 3 -m 5 $update_curl/qsc.sh)
if [ "$(echo -E "$up1" | egrep '^# ##' | sed -n '$p')" = '# ##' -a "$(echo -E "$up2" | egrep '^# ##' | sed -n '$p')" = '# ##' ]; then
	echo -E "$up1" > $MODDIR/module.prop &&
	echo -E "$up2" > $MODDIR/qsc.sh &&
	module_versionCode=$(cat $MODDIR/module.prop | egrep 'versionCode=' | sed -n 's/.*versionCode=//g;$p')
	if [ "$Host_version" -lt "$module_versionCode" ]; then
	sed -i "s/。 .*/。 当前版本是由模块脚本于：$(date +%Y%m%d) $(date +%T) 自动更新！/g" $MODDIR/module.prop > /dev/null 2>&1
	fi
	chmod 0755 $MODDIR/qsc.sh
fi

