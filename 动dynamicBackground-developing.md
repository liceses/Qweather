### 目的

#### 背景
已经按照[设计文档](天空模拟系统——V3设计文档.md)实现了两次,都不能实现背景的无缝切换,而且各个layer 几乎没有正常运行

#### 第三次实现:
要求每个组件都有可控的验证方法,能输出到程序输出的**一定要输出**,不能输出的**一定要停下来**让我运行验证效果
参照[设计文档](天空模拟系统——V3设计文档.md)实现
有不清楚的地方立刻问我
### 步骤
#### 一,实现渲染层和中间层 和 debug panel
    - SkyState 
    - BackgroundManager
    - TransitionController (先不做防抖,便于排查错误)
    - qml 端  DebugPanel
    - WeatherBackground 容器
    - 各 Layer,Shader + 公共库
  实现效果,动态背景在debug面板可以调试,过渡动态达到要求 