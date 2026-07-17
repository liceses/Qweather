# QWeather — 动态天气桌面应用

基于 Qt 6 + QML 的跨平台天气应用，核心特色是 **V3 动态天空模拟系统**——根据实时气象数据和天文位置，驱动 GPU shader 渲染逼真的天空背景。

## 功能

- **实时天气** — 接入和风天气 API，支持城市搜索、多城市跟踪
- **动态天空背景** — 7 段天空色模型（深夜/蓝调/金粉/白天/暖午后/橙红/紫调），GPU shader 实时渲染
- **天气特效** — 云层（3 层 fBM 噪声 + domain warping）、雨丝（密度/速度联动）、雪花、雾霾、闪电
- **昼夜变化** — 基于城市经纬度计算本地日出日落，太阳/月亮位置实时追踪
- **平滑过渡** — TransitionController 管理 Layer 激活/去激活时序，防抖机制
- **城市详情** — 逐日/逐时预报、空气质量、太阳辐射、月相等
- **收藏管理** — 收藏城市、固定到侧边栏
- **调试面板** — 实时调校所有天空参数，一键保存配置，自动演示模式

## 技术栈

| 层 | 技术 |
|----|------|
| 前端 | Qt 6.11 / QML / Qt Quick |
| 后端 | C++17（无 RTTI/异常） |
| 渲染 | GLSL 着色器 (qsb) + ShaderEffect |
| 网络 | 和风天气 API (HTTPS) |
| 构建 | CMake 3.16+ |
| 编译器 | MinGW / MSVC |

## 快速开始

### 前置条件

- Qt 6.10+（含 Quick、Network、Sql、Charts、ShaderTools 模块）
- CMake 3.16+
- C++17 编译器

### 构建

```bash
# 配置
cmake --preset default

# 编译
cmake --build build

# 运行
./build/Desktop_Qt_6_11_1_MinGW_64_bit_Debug/appqml1.exe
```

### API 密钥

项目使用和风天气 API。密钥在 `weatherApi.h` 中配置：

```cpp
static const QString KEY = "your_key_here";
```

## 架构概览

### V3 天空模拟系统

```
GlobalClock (16ms timer)
    → BackgroundManager (状态管理)
        → AstronomyModel (太阳/月亮位置计算)
        → WeatherProfileDB (天气码→渲染参数映射)
        → TransitionController (Layer 激活/去激活编排)
            → QML Loader + ShaderEffect (GPU 渲染)
```

### Layer 结构

| Layer | z-index | 类型 | 说明 |
|-------|---------|------|------|
| SkyLayer | 0 | 始终渲染 | 天空色渐变 + 日月 + 星星 |
| AtmosphereLayer | 10 | 始终渲染 | 黄昏散射光晕 |
| CloudLayer | 20 | 条件激活 | 3 层 fBM 域扭曲云 |
| WeatherLayer | 30 | 条件激活 | 雨/雪粒子 |
| FogLayer | 40 | 条件激活 | 雾/霾/沙尘 |
| LightningLayer | 50 | 条件激活 | 闪电闪光 |

### 数据流

```
API → WeatherProfileDB → SkyState → TransitionController → Layer
         ↓                      ↑
    AstronomyModel → buildAtmosphereChanges()
```

### 调校工具

Debug 面板（Ctrl+Shift+B）支持：
- 手动调节所有 SkyState 参数
- 时间控制滑块预览全天变化
- 天气码模拟 + 一键保存配置到 `weather_profiles.json`
- 自动演示模式（快速/完整）

## 项目结构

```
├── Main.qml              # 主窗口 + 布局
├── *.qml                 # 页面组件 (18 个)
├── shaders/
│   ├── *.frag            # GLSL 着色器 (7 个)
│   └── common/*.glsl     # 公共库 (7 个)
├── *.h / *.cpp           # C++ 后端 (14 对)
├── icons/                # SVG 图标
├── CMakeLists.txt
└── weather_profiles.json # 用户调校的配置（自动生成）
```

## 许可

BSD-3-Clause

---

*数据来源：[和风天气](https://www.qweather.com/)*
