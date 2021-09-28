# QuantitativeStopCharging_magisk
这是一个运行在安卓设备上的QSC定量停充magisk模块。

This is a quantitative stop charging magick module running on Android devices.

用于指定电量、指定温度自动停止供电、恢复供电、涓流充电(伪电池闲置模式、伪旁路充电)、游戏模式自定义充电电流。

It is used to automatically stop power supply, restore power supply, trickle charging (pseudo battery idle mode, pseudo bypass charging) and customize charging current.

配置文件路径：/data/adb/modules/QuantitativeStopCharging/config.conf，日志文件log.log。

Configuration file path: /data/adb/modules/QuantitativeStopCharging/config.conf, log file: log.log.

支持功能（在配置文件里可选开启或关闭）：

Supported functions (optional on or off in the configuration file):

1.自定义关机电量。

1. Custom shutdown power.

2.自定义电量停止充电、恢复充电，停充之前可自定义继续充电一段时间。

2. The user-defined power stops charging or resumes charging. You can set to continue charging for a period of time before stopping charging.

3.自定义电量涓流充电（伪电池闲置模式、伪旁路充电）。

3. Custom power trickle charging (pseudo battery idle mode, pseudo bypass charging).

4.游戏模式：指定APP自定义充电电流。

4. Game mode: specify app custom charging current.

5.开关温控模式：指定温度停止充电、恢复充电。

5. Switch temperature control mode: stop charging and resume charging at the specified temperature.

6.电流温控模式：指定温度限制充电电流为自定义充电电流。

6. Current temperature control mode: specify the temperature limit charging current as user-defined charging current.

7.自定义开关路径、自定义电流文件路径、自定义其它文件参数。

7. Customize switch path, current file path and other file parameters.

8.自定义温度传感器路径：使用 “temp.sh” 脚本可获取所有温度传感器路径脚本，模块默认使用电池温度，脚本可获取其它温度传感器的路径，其中名称battery为电池温度，获取到路径填入配置文件即可（不填则默认使用电池温度，个别设备电池温度是固定不变化的）。

8. User defined temperature sensor path: use the "temp. Sh" script to obtain the path scripts of all temperature sensors. The module uses the battery temperature by default. The script can obtain the paths of other temperature sensors, where the name battery is the battery temperature. Fill in the configuration file after obtaining the path (if it is not filled in, the battery temperature is used by default, and the battery temperature of individual devices is fixed) 。

模块逻辑：不充电不触发模块功能（自定义关机电量除外），仅在充电时触发，定量停充-开关温控-涓流模式-电流温控-游戏模式-默认电流模式，从前至后匹配，符合就触发，只触发一个，不会同时触发，然后结束，再循环匹配。

Module logic: without charging, the module function is not triggered (except for custom shutdown power). It is triggered only during charging. Quantitative charging stop - switch temperature control - trickle mode - current temperature control - game mode - default current mode. It is matched from front to back. If it meets, it will be triggered. Only one will be triggered. It will not be triggered at the same time, and then it will end. Recirculation matching.

如果对你有帮助，可向我支付宝捐赠：410154425@qq.com

If you have any help, you can donate to Alipay: 410154425@qq.com
