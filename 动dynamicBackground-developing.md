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

- AstronomyModel 
  - 细化文档 5.4 节要求月亮位置来自 weatherApi.astronomyMoon API 数据，但实际 AstronomyModel::update()（AstronomyModel.cpp:54-58）仅根据太阳对跖点加上 15° 偏移来计算月亮位置，未使用 API 返回的真实月亮坐标。
- weatherProfile 完善
- 天空色模型（7 时段 × 3 色）
  - 文档 5.2 节定义了 7 段 × 3 色的天空模型（深夜/蓝调/金粉/白天/暖午后/橙红/紫调），但实际 BackgroundManager::updateAtmosphere()（BackgroundManager.cpp:184-233）只实现了 3 段（白天/黄昏/夜晚），使用 3 组硬编码颜色。混合逻辑也只有简单的线性 mixColor()，没有文档描述的 7 时段精细色调。

| 时段 | sunProgress | 天顶 | 地平线 | 环境色 |
|---|---|---|---|---|
| 深夜 | < -0.3 | `#0a0a1a` | `#0d0d28` | `#050510` |
| 蓝调(日出前) | -0.3~0 | `#1a2a5a` | `#4a3060` | `#0a0a20` |
| 金粉(日出) | 0~0.15 | `#4a6fa5` | `#f4a460` | `#e07050` |
| 白天 | 0.15~0.7 | `#4a90d9` | `#87ceeb` | `#c8e0f0` |
| 暖午后 | 0.7~0.9 | `#5a8ab5` | `#d4996a` | `#c0b0a0` |
| 橙红(日落) | 0.9~1.0 | `#3a5a8a` | `#e07840` | `#a03030` |
| 紫调(日落后) | 1.0~1.3 | `#2a1a4a` | `#602040` | `#0a0a20` |

各时段间 `mixColor()` 平滑过渡。天气类型在此基础上调整饱和度/亮度。
- 过渡机制（TransitionController）
三层过渡模型

| 过渡类型 | 举例 | 机制 | 时长 |
|---|---|---|---|
| 完全相同 | 305→305 | NO-OP | — |
| 同类型 ±intensity | 305→307 | 参数平滑（shader 内插值） | ~400ms |
| 同类型 ±variant | 307→302 | 参数平滑 | ~400ms |
| 同类型 ±两者 | 305→303 | 参数平滑 | ~400ms |
| 跨类型 | 305→400 | Loader 切换 + transitionProgress 动画 | ~600ms |

### 5.2 Layer 激活时序

| Layer | 激活延迟 | 淡入时长 | 去激活 |
|---|---|---|---|
| CloudLayer | +100ms | 600ms | fadeOut 600ms → unload |
| WeatherLayer | +400ms(cloud) / +100ms | 600ms | fadeOut 600ms |
| FogLayer | +100ms | 400ms | fadeOut 400ms |
| LightningLayer | instant | instant | instant |

### 5.3 防抖

`m_transitionId` 自增计数器 + `QTimer::singleShot` lambda 捕获 localId：新请求递增 ID，旧回调检测 ID 不匹配则 return。

#### 当前待解决的关键问题

1. **Main.qml 数据流未接入**（最高优先级）— `connections weatherApi` 中尚未调用 `backgroundManager.updateWeather()`/`updateSunTimes()`/`updateMoonData()`，系统当前无法跟随真实天气变化
2. **WeatherProfile 68 码映射未完整实现** — 当前为骨架，需要在 `WeatherProfileDB::initProfiles()` 中补全全部 68 个码
3. **TransitionController 防抖未实现** — `m_transitionId` 机制标注为"先不做"
4. **`weatherVariant` 字段未在 SkyState 中暴露** — `WeatherLayer.qml` 分派器需要 variant 信息来选择粒子变体（雷暴/冰雹/雨夹雪等）

settings:
  - 黑夜模式只控制文字和icon颜色 在深浅之间切换,字体深浅具体颜色值待定

rain.frag : 
  - 雨强度小的时候 , 雨丝不明显 ,发现现在版本雨强度只调节雨丝可见度 ,而非密度,速度等 ; 雨强度小,可见度适当小,主要是密度和下落速度减小一些