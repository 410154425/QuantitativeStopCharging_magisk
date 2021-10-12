# QuantitativeStopCharging_magisk
这是一个运行在安卓设备上的QSC定量停充magisk模块。

[下载页面](https://github.com/410154425/QuantitativeStopCharging_magisk/releases)选择压缩包QSC_magisk_***.zip，使用Magisk从本地安装。

用于指定电量、指定温度自动停止供电、恢复供电、涓流充电(伪电池闲置模式、伪旁路充电)、游戏模式自定义充电电流。

配置文件路径：/data/adb/modules/QuantitativeStopCharging/config.conf，日志文件log.log。

支持功能（在配置文件里可选开启或关闭）：

1.自定义关机电量。

2.自定义电量停止充电、恢复充电，停充之前可自定义继续充电一段时间。

3.自定义电量涓流充电（伪电池闲置模式、伪旁路充电）。

4.游戏模式：指定APP自定义充电电流。

5.开关温控模式：指定温度停止充电、恢复充电。

6.电流温控模式：指定温度限制充电电流为自定义充电电流。

7.自定义开关路径、自定义电流文件路径、自定义其它文件参数。

8.自定义温度传感器路径：使用 “temp.sh” 脚本可获取所有温度传感器路径脚本，模块默认使用电池温度，脚本可获取其它温度传感器的路径，其中名称battery为电池温度，获取到路径填入配置文件即可（不填则默认使用电池温度，个别设备电池温度是固定不变化的）。

