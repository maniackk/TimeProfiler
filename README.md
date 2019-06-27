# TimeProfiler
Recording all OC methods in the main thread takes time


<div align="center"><img width="300" height="533.6" src="TimeProfiler.png"></div>

# 特性
1. 记录所有在主线程运行的OC方法的耗时情况
2. 支持设置记录的最大深度和最小耗时


# 支持机型
iPhone5s及更新真机（arm64）

# 用法
## 启动监控
在以下地方：
1. 程序 main 函数入口；
2. AppDelegate 中的 application:didFinishLaunchingWithOptions:；
3. 你想开始的监控点

导入头文件#include "TPCallTrace.h"；调用startTrace()。

把TimeProfiler文件夹放入项目中，run App后，摇一摇App，就可以看到主线程运行的OC方法的耗时情况

# 原理介绍
[博客](https://wukaikai.tech/2019/06/27/%E7%9B%91%E6%8E%A7%E6%89%80%E6%9C%89%E7%9A%84OC%E6%96%B9%E6%B3%95%E8%80%97%E6%97%B6/)

