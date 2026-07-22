# QWeather — 动态天气桌面应用

基于 Qt 6 + QML 的跨平台天气应用，核心特色是 **V3 动态天空模拟系统**——根据实时气象数据和天文位置，驱动 GPU shader 渲染逼真的天空背景。

**当前分支**: `feat/portable` — 绿色便携版，所有配置文件与 exe 同目录，删除即清。

## 功能

- **实时天气** — 接入和风天气 API，支持城市搜索、多城市跟踪
- **动态天空背景** — 7 段天空色模型（深夜/蓝调/金粉/白天/暖午后/橙红/紫调），GPU shader 实时渲染
- **天气特效** — 云层（3 层 fBM 噪声 + domain warping）、雨丝（密度/速度联动）、雪花、雾霾、闪电
- **昼夜变化** — 基于城市经纬度计算本地日出日落，太阳/月亮位置实时追踪
- **平滑过渡** — TransitionController 管理 Layer 激活/去激活时序，防抖 + 渐变
- **城市详情** — 逐日/逐时预报、空气质量、太阳辐射、月相、天气预警、生活指数、分钟降水
- **收藏管理** — 收藏城市、固定到侧边栏
- **调试面板** — `Ctrl+Shift+B` 实时调校所有天空参数，自动演示模式
- **API 请求统计** — 设置页查看各端点调用次数、缓存命中率

## 技术栈

| 层 | 技术 |
|----|------|
| 前端 | Qt 6.11 / QML / Qt Quick Controls (Fusion 主题) |
| 后端 | C++17（无 RTTI/异常） |
| 渲染 | GLSL 着色器 (7 个 .frag → .qsb) + ShaderEffect |
| 网络 | 和风天气 API (HTTPS, 24 个端点) |
| 缓存 | SQLite（键值存储 + TTL 过期） |
| 构建 | CMake 3.16+ |
| 编译器 | MinGW / GCC / Clang / Android NDK |

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

# 运行（先设置 API Key）
set QW_API_KEY=your_key_here
./build/appqml1.exe
```

### API 密钥

项目使用和风天气 API，**源码中不包含任何 API Key**，需自行申请：

1. 前往 [和风天气控制台](https://console.qweather.com) 注册并创建项目
2. 获取 API Key（推荐 JWT 方式，兼容 API Key）
3. 以下方式任选其一配置：

   **方式一：环境变量（推荐）**
   ```bash
   set QW_API_KEY=your_key
   ./appqml1.exe
   ```

   **方式二：应用设置页**
   启动后在 `设置 → API 设置` 中输入 Key，自动保存到 `settings.json`

**安全说明**：API Key 以 Base64 编码存储在 `settings.json` 中（非加密，仅防肉眼扫描）。请勿将 `settings.json` 提交到版本控制。

## 文件分布（便携版）

所有运行时数据与 exe 同目录：

```
{exe}/
├── appqml1.exe
├── weather_cache.db       # SQLite 缓存（自动生成）
├── weather_profiles.json  # 用户调校的天气配置（自动生成）
├── settings.json          # 应用设置含 API Key（自动生成）
└── api_stats.json         # API 请求统计（自动生成）
```

删除 exe 目录即完全清理，不留痕迹。

## 架构概览

### V3 天空模拟系统

```
GlobalClock (16ms timer)     ← GPU 着色器动画时间源
    → BackgroundManager      ← 天空状态中央控制器
        → AstronomyModel     ← 太阳/月亮位置计算（简化天文公式）
        → WeatherProfileDB   ← 天气码→渲染参数映射（68 个默认）
        → TransitionController  ← Layer 激活/去激活编排（迟滞阈值 + 延迟时序）
            → QML Loader + ShaderEffect (GPU 渲染 60fps)
```

### Layer 结构

| Layer | z-index | 类型 | 说明 |
|-------|---------|------|------|
| SkyLayer | 0 | 始终渲染 | 天空色渐变 + 日月 + 星星 |
| AtmosphereLayer | 10 | 始终渲染 | 黄昏散射光晕 |
| CloudLayer | 20 | 条件激活 | 3 层 fBM 域扭曲云 + 4 步光线步进 |
| WeatherLayer | 30 | 条件激活 | 雨/雪粒子（12 层网格/60 粒子） |
| FogLayer | 40 | 条件激活 | 雾/霾/沙尘（3 种变体） |
| LightningLayer | 50 | 条件激活 | 3 秒 epoch 随机闪电闪烁 |

### 数据流

```
API (HTTPS) → WeatherAPI (统一路由 + 缓存)
                ↓
        Data Stores (Forecast / AirQuality / Solar / CityDetail)
                ↓
       QQmlApplicationEngine (10 个 setContextProperty)
                ↓
            QML Pages (7 个页面)
                ↓
    WeatherBackground (ShaderEffect 6 层栈)
                ↓
          GPU (GLSL #version 450, ACES 色调映射)
```

### 调校工具

Debug 面板（`Ctrl+Shift+B`）支持：
- 手动调节所有 SkyState 参数（天文/天气/大气/变体）
- 时间控制滑块预览全天变化
- 天气码模拟 + 一键保存配置
- 自动演示模式（快速/完整）

### API 请求统计

设置页 → "API 请求统计" 查看每个端点：
- 请求次数
- 缓存命中数
- 命中率（>50% 绿色标记）

重启不清零（持久化到 `api_stats.json`）。

## 项目结构

```
├── Main.qml                # 主窗口 + 侧边栏导航 + 页面路由
├── *.qml                   # 页面/组件 (19 个)
├── ApiUsagePage.qml        # API 请求统计页
├── shaders/
│   ├── sky.frag            # 天空渐变 + 太阳/月亮/星星
│   ├── cloud.frag          # 体积云（raymarching）
│   ├── rain.frag           # 雨粒子（12 层网格）
│   ├── snow.frag           # 雪花粒子（60 粒子）
│   ├── fog.frag            # 雾/霾/沙尘
│   ├── lightning.frag      # 闪电闪烁
│   └── atmosphere.frag     # 黄昏散射
├── *.h / *.cpp             # C++ 后端 (14 对)
│   ├── WeatherAPI          # 24 个 API 端点封装 + SQLite 缓存
│   ├── BackgroundManager   # 天空系统中央控制器
│   ├── SkyState            # 20 字段统一渲染契约
│   ├── TransitionController # Layer 过渡编排
│   └── AppSettings         # 应用设置（JSON 持久化）
├── icons/                  # 7 个 SVG 图标
├── CMakeLists.txt
└── .gitignore
```

## 许可

BSD-3-Clause

---

*数据来源：[和风天气](https://www.qweather.com/)*
