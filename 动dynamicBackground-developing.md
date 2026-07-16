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


## todo
- debug里调节时间流速
- shader 效果
    - 天空渐变 — 天顶/地平线颜色、曝光、黄昏色调
    - 太阳 — 位置、光晕大小、颜色（低角度橙红效果）
    - 月亮 — 位置、月相 SDF、月光亮度
    - 星星 — 数量、闪烁速度、亮度曲线
    - 云层 — fBM 噪声阈值、层数、漂移速度、覆盖率过渡
    - 雨丝 — 长度、密度、下落速度、风偏移
    - 雪花 — 大小、摇摆幅度、下落速度
    - 雾 — 颜色（乳白/黄灰/棕褐）、浓度渐变、颗粒感
    - 闪电 — 频率、亮度、双闪间隔

| Shader | 核心效果 | 粒子数 |
|---|---|---|
| `sky.frag` | 三色渐变 + 太阳光晕 + 月亮 SDF + 星空 | ≤50 星星 |
| `atmosphere.frag` | twilight 色调 + 散射 + 曝光 | 0 |
| `cloud.frag` | 2~3 层 fBM 云噪声漂移 | 0 |
| `rain.frag` | 雨丝粒子 + 雷暴/冰雹 variant | ≤60 |
| `snow.frag` | 雪花粒子 + 雨夹雪 variant | ≤60 |
| `fog.frag` | 雾(乳白)/霾(黄)/沙尘(棕褐)色调 | 0 |
| `lightning.frag` | 间歇 3~8s 全屏闪电 | 0 |



Mainqml:
 - 页面切换动画
 - 文字切换动画

dashboard: 
 - 卡片出栈动画:卡片被叉掉->卡片淡出,在淡出卡片的右侧的卡片向左补齐

settings:
  - 黑夜模式只控制文字和icon颜色 在深浅之间切换,字体深浅具体颜色值待定
  - API设置
  - citycard显示数量

rain.frag : 
  - 雨强度小的时候 , 雨丝不明显 ,发现现在版本雨强度只调节雨丝可见度 ,而非密度,速度等 ; 雨强度小,可见度适当小,主要是密度和下落速度减小一些
  - 当曝光高到要自适应遮罩启动的时候，雨强小 视觉上雨滴完全不可见了，

weatherApi :
  - warningnow 请求26/10/1 就会被废弃
  - apikey验证格式老旧,添加对新JWT验证的支持

global clock ： 
 - 时间本土化未实现，典型bug:newyork 在凌晨2点，天文模型传给背景的还是白天

weatherBackgroundDebugPanel:
 - 调节滑条时面板透明,只剩滑条,方便观察
 - 添加一个演示天气动态背景的炫技功能:展示一天的天文变化,包括所有的天气

cityDetail:
 - 宽度全屏的堆叠卡片改为网格卡片,根据内容确定大小

重新设计:
citylist是一个类似栈的结构
前n+1个是显示区(n即dashboard要显示的城市卡片数)
其中栈顶是focusCity 其余是citycards
城市启动时初始化list中入栈n+1个城市
优先级:收藏>历史(如果有历史城市的话)>热门

```
citylist(当n=4):
| A | B | C | D | E |
[    citycard   ]  ^
                  focuscity  
```
dashboard
citycard行为:
显示对应citylist显示区除focuscity的n个城市
实时同步
点击卡片切换焦点
双击进入城市详情同时进入焦点
card新增右上角小叉号,hover时显示,点击将对应城市出栈
焦点城市行为:
无论何种情况触发了切换焦点城市x均:
查询x是否在citylist中,
若在则将x提升至栈顶
若不在,则入栈到栈顶
dashboard的城市大字始终与焦点城市城市名相同
