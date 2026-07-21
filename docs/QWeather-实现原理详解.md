# QWeather（qml1）实现原理详解

> 本文档从类、函数、组件级别详细阐述 QWeather 天气应用的完整实现原理。
> 版本: v0.1 | 框架: Qt 6.11 + QML | 语言: C++17 / QML / GLSL

---

## 目录

1. [项目总览](#1-项目总览)
2. [构建系统](#2-构建系统)
3. [入口点 main.cpp](#3-入口点-maincpp)
4. [C++ 数据层](#4-c-数据层)
   - 4.1 [SkyState.h — 统一渲染状态契约](#41-skystateh--统一渲染状态契约)
   - 4.2 [WeatherCache — SQLite 缓存层](#42-weathercache--sqlite-缓存层)
   - 4.3 [WeatherAPI — 和风天气 API 封装](#43-weathercapi--和风天气-api-封装)
   - 4.4 [ForecastStore — 预报数据层](#44-forecaststore--预报数据层)
   - 4.5 [AirQualityStore — 空气质量数据层](#45-airqualitystore--空气质量数据层)
   - 4.6 [SolarAstronomyStore — 太阳/天文数据层](#46-solarastronomystore--太阳天文数据层)
   - 4.7 [CityDetailStore — 城市详情聚合层](#47-citydetailstore--城市详情聚合层)
   - 4.8 [AppSettings — 应用设置](#48-appsettings--应用设置)
5. [V3 天空模拟系统（C++）](#5-v3-天空模拟系统c)
   - 5.1 [GlobalClock — 全局时间源](#51-globalclock--全局时间源)
   - 5.2 [AstronomyModel — 太阳/月亮位置计算](#52-astronomymodel--太阳月亮位置计算)
   - 5.3 [WeatherProfile — 天气码配置数据库](#53-weatherprofile--天气码配置数据库)
   - 5.4 [BackgroundManager — 天空系统中央控制器](#54-backgroundmanager--天空系统中央控制器)
   - 5.5 [TransitionController — 图层过渡编排器](#55-transitioncontroller--图层过渡编排器)
6. [QML 前端](#6-qml-前端)
   - 6.1 [Main.qml — 主应用窗口](#61-mainqml--主应用窗口)
   - 6.2 [页面组件](#62-页面组件)
   - 6.3 [天空系统 QML 组件](#63-天空系统-qml-组件)
   - 6.4 [可复用 UI 组件](#64-可复用-ui-组件)
7. [GLSL 着色器系统](#7-glsl-着色器系统)
   - 7.1 [着色器文件](#71-着色器文件)
   - 7.2 [通用 GLSL 库](#72-通用-glsl-库)
8. [数据流与状态管理](#8-数据流与状态管理)
9. [CMakeLists.txt 构建配置详解](#9-cmakeliststxt-构建配置详解)

---

## 1. 项目总览

QWeather 是一款基于 **Qt 6 + QML** 的桌面天气应用，核心功能包括：

- **数据来源**: 和风天气 API（24 个独立端点）
- **数据缓存**: SQLite（键值对 + TTL 过期机制）
- **动态背景**: V3 天空模拟系统，使用 GLSL 着色器（GPU 渲染）实时驱动 7 层天空效果
- **天文计算**: 基于经纬度+日出日落时间的简化天文公式，计算太阳/月亮位置
- **天气码映射**: 68 个默认天气码→渲染参数映射表，支持 JSON 持久化和运行时调校
- **UI 风格**: 玻璃态（Frosted Glass），半透明 ARGB 叠加 + 1px 边框，无 backdrop-blur
- **图表**: Qt Charts（SplineSeries / LineSeries）

**架构模式**: C++ 后端（数据层 + 状态管理）通过 `QQmlApplicationEngine` 的上下文属性注入到 QML 前端，QML 负责 UI 渲染和交互，通过 `Q_INVOKABLE` 调用 C++ 方法。

**模块数量统计**:
| 类型 | 数量 |
|------|------|
| C++ 头文件 | 14 |
| C++ 源文件 | 13 |
| QML 文件 | 19 |
| GLSL 着色器 | 7 |
| GLSL 通用库 | 7 |
| SVG 图标 | 7 |

---

## 2. 构建系统

### CMakeLists.txt — 构建入口

```cmake
cmake_minimum_required(VERSION 3.16)
project(qml1 VERSION 0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
```

**依赖模块**: `Qt6::Quick Qt6::Network Qt6::Sql Qt6::Charts Qt6::Widgets Qt6::ShaderTools`

**构建目标**:
- `qt_add_executable(appqml1 main.cpp)` — 可执行体
- `qt_add_qml_module(appqml1 URI qml1 ...)` — QML 模块，含 28 个 QML 文件 + 14 对 C++ 源文件
- `qt_add_resources(appqml1 "icons" ...)` — 7 个 SVG 图标嵌入为 Qt 资源
- `qt_add_shaders(appqml1 "shaders" ...)` — 7 个 `.frag` 着色器编译为 `.qsb`（Qt Shader Baker）

**CMakePresets.json** — 仅含 MinGW 64 位桌面构建预设：
```json
{
    "CMAKE_PREFIX_PATH": "D:/Qt/Qt6/6.11.1/mingw_64",
    "CMAKE_CXX_COMPILER": "D:/Qt/Qt6/Tools/mingw1310_64/bin/g++.exe"
}
```

---

## 3. 入口点 main.cpp

`main.cpp` 是应用程序的唯一入口，仅 76 行，执行以下顺序：

### 3.1 初始化步骤

```cpp
// 1. 设置 QML 主题
qputenv("QT_QUICK_CONTROLS_STYLE", "Fusion");

// 2. 创建 QApplication（必须，因 Qt Charts 需要）
QApplication app(argc, argv);

// 3. 注册元类型
qRegisterMetaType<QJsonArray>("QJsonArray");
qRegisterMetaType<QJsonObject>("QJsonObject");
qRegisterMetaType<SkyState>("SkyState");
```

### 3.2 创建数据层对象（栈分配，生命周期=app 生命周期）

| 对象 | 类型 | 依赖关系 |
|------|------|----------|
| `cache` | `WeatherCache` | 独立，SQLite |
| `weatherapi` | `WeatherAPI` | 依赖 `cache`（setCache） |
| `forecastStore` | `ForecastStore` | 依赖 `weatherapi` |
| `airQualityStore` | `AirQualityStore` | 依赖 `weatherapi` |
| `appSettings` | `AppSettings` | 独立，QSettings |
| `solarAstronomyStore` | `SolarAstronomyStore` | 依赖 `weatherapi` + `appSettings` |
| `cityDetailStore` | `CityDetailStore` | 依赖 `weatherapi` |
| `globalClock` | `GlobalClock` | 独立 |
| `bgManager` | `BackgroundManager` | 依赖 `TransitionController` |
| `transitionCtrl` | `TransitionController` | 独立 |

### 3.3 注入到 QML 上下文

将 10 个 C++ 对象通过 `engine.rootContext()->setContextProperty()` 注册为 QML 全局属性：

```cpp
engine.rootContext()->setContextProperty("weatherApi", &weatherapi);
engine.rootContext()->setContextProperty("weatherCache", &cache);
// ... 等 10 个属性
```

### 3.4 启动

```cpp
globalClock.start();                       // 启动 60fps 定时器
engine.loadFromModule("qml1", "Main");     // 加载 Main.qml
return QApplication::exec();              // 进入事件循环
```

---

## 4. C++ 数据层

### 4.1 SkyState.h — 统一渲染状态契约

**文件**: `SkyState.h`（87 行）
**类型**: `Q_GADGET` 结构体（非 QObject，值类型）

**作用**: 作为 C++ ↔ QML ↔ GLSL 着色器之间的**数据契约**，包含所有天空渲染参数。

**字段分组（共 20 个字段）**:

```
天文（6）:  solarAltitude, solarAzimuth, moonAltitude, moonAzimuth, moonPhase, moonIllum
大气（5）:  zenithColor, horizonColor, ambientColor, exposure, twilightFactor
天气（6）:  cloudCoverage, rainIntensity, snowIntensity, fogDensity, lightningProb, starVisibility
变体（3）:  cloudVariant, fogVariant, weatherVariant
```

**关键方法**:

| 方法 | 说明 |
|------|------|
| `dump()` | 格式化输出所有字段的调试字符串 |

**重要细节**: 使用 `Q_PROPERTY(... MEMBER ...)` 宏，每个字段直接暴露给 QML 属性绑定系统，无需 getter/setter。

---

### 4.2 WeatherCache — SQLite 缓存层

**文件**: `WeatherCache.h/.cpp`（37+102 行）
**父类**: `QObject`

#### 类职责

SQLite 键值对缓存，带 TTL 过期机制。数据库文件位于 `{exe目录}/weather_cache.db`。

#### 数据库 Schema

```sql
CREATE TABLE IF NOT EXISTS cache (
    k TEXT PRIMARY KEY,    -- 缓存键
    data TEXT,             -- JSON 数据
    ts INTEGER             -- 时间戳（Unix 秒）
);
```

#### 公开方法

| 方法 | 说明 |
|------|------|
| `get(key, ttlSeconds)` | 查缓存，返回 JSON 字符串（过期则自动删除并返回空） |
| `set(key, json)` | 写入缓存（INSERT OR REPLACE） |
| `cleanExpired(ttl)` | 清除过期数据 |
| `clearAll()` | 清除全部数据 |
| `save(key, value)` | 持久化存储（无 TTL，用于收藏/历史/设置） |
| `load(key)` | 持久化读取 |

#### 缓存键格式

```
"{prefix}:{location}"         例: "weather_now:101010100"
"{prefix}:{location}:{date}"  例: "astro_sun:101010100:20240717"
```

---

### 4.3 WeatherAPI — 和风天气 API 封装

**文件**: `weatherApi.h/.cpp`（171+607 行）
**父类**: `QObject`

#### 类职责

封装和风天气全部 24 个 API 端点，统一请求路由（`sendRequest` → `onReplyFinished` → handler），内置缓存集成。

仅实现18个handler,仅有8个api请求方法实现缓存劫持

#### 核心架构

```
QML 调用 Q_INVOKABLE 方法    ← 缓存劫持,减少api冗余请求,前端无感
    ↓
sendRequest(url, type)      ← 构建 QNetworkRequest，标记请求类型
    ↓
QNetworkAccessManager::get  ← 发起 HTTP GET
    ↓
onReplyFinished(reply)      ← 统一回调，解析 type 属性，统一路由
    ↓
缓存写入                    ← 按 type 计算缓存键和 TTL
    ↓
handleXxx(data)             ← 分发到具体 handler
    ↓
emit xxxReady(result)       ← 发射信号给 QML/Store
```

#### 请求类型枚举 `ApiRequestType`

24 个枚举值，每个对应一个 API 端点：
- 地理: `CityLookup`, `CityTop`
- 天气: `WeatherNow`, `WeatherDaily`, `WeatherHourly`
- 格点天气: `GridWeatherNow`, `GridWeatherDaily`, `GridWeatherHourly`
- 降水: `MinutelyPrecip`
- 预警: `WarningNow`
- 指数: `Indices`
- 空气质量: `AirCurrent`, `AirHourly`, `AirDaily`
- 时光机: `HistoricalWeather`, `HistoricalAir`
- 台风: `StormList`, `StormTrack`, `StormForecast`
- 海洋: `OceanTide`
- 太阳辐射: `SolarRadiation`
- 天文: `AstronomySun`, `AstronomyMoon`, `SolarElevationAngle`

#### 缓存 TTL 配置（`cacheConf()` 函数）

| API 类型 | 缓存前缀 | TTL（秒） |
|----------|----------|-----------|
| 实时天气 | weather_now | 600（10分钟） |
| 逐日预报 | weather_daily | 3600（1小时） |
| 逐小时预报 | weather_hourly | 1800（30分钟） |
| 空气质量 | air_current | 1800（30分钟） |
| 天文数据 | astro_sun/solar | 86400（24小时） |
| 城市搜索 | city_lookup | 86400（24小时） |

#### Handler 模式

每个 API 端点对应一个 `handleXxx` 函数（共 18 个 handler），统一从 JSON 响应中提取数据，发射对应信号。例如：

```cpp
// 调用链: weatherNow(loc) → sendRequest → onReplyFinished → handleWeatherNow
void WeatherAPI::handleWeatherNow(const QByteArray &d, const QString &loc) {
    QJsonObject obj = QJsonDocument::fromJson(d).object()["now"].toObject();
    obj["_location"] = loc;           // 注入 location 字段用于路由
    emit weatherNowReady(obj);
}
```

#### emit 信号广播模式

每个接受者 收到全部订阅信号，根据城市选择性处理

```
weatherApi.weatherNow("101010100")
  → HTTP GET → handleWeatherNow(data, "101010100")
    → obj["_location"] = "101010100"
    → emit weatherNowReady(obj)
                                     ┌──────────────────────┐
                   ┌─────────────────┤ Main.qml             │
                   │                 │ onWeatherNowReady:    │
                   │                 │ 不按城市过滤，全收   │
                   │                 └──────────────────────┘
                   │                 ┌──────────────────────┐
                   ├─────────────────┤ CityDetailStore      │
                   │                 │ onWeatherNowReady:    │
                   │                 │ 检查 _location==m_cityId │
                   │                 └──────────────────────┘
                   │                 ┌──────────────────────┐
                   └─────────────────┤ ForecastStore        │
                                     │ (不连 weatherNowReady)│
                                     └──────────────────────┘
```

---

### 4.4 ForecastStore — 预报数据层

**文件**: `ForecastStore.h/.cpp`（57+124 行）
**父类**: `QObject`

#### 类职责

管理城市列表、触发预报 API 调用、将 JSON 预处理为图表坐标。

#### Q_PROPERTY

| 属性 | 类型 | 说明 |
|------|------|------|
| `cities` | QVariantList | 城市列表（前 4 个被使用） |
| `range` | QString | 预报范围: "24h"/"72h"/"168h"/"3d"/"7d"/... |
| `mode` | QString | 由 range 派生: 含 'h'→"hourly"，否则→"daily" |
| `chartData` | QVariantMap | 图表数据: `{cityId_hourly: [{x,y},...], cityId_info: {...}}` |

#### key 方法

| 方法 | 说明 |
|------|------|
| `setCities(cities)` | 设置城市列表 → 发射 citiesChanged → refreshAll |
| `setRange(range)` | 设置预报范围 → refreshAll |
| `refreshAll()` | 遍历前 4 个城市，按 hour/daily 模式调用 API |
| `onWeatherDailyReady` | 解析 daily JSON: `fxDate→x, tempMax→yMax, tempMin→yMin` |
| `onWeatherHourlyReady` | 解析 hourly JSON: `fxTime→x, temp→y` |

**写时复制模式**: 每次更新 `m_chartData` 时创建新 QVariantMap，确保 QML 属性绑定检测到引用变化：

```cpp
QVariantMap newData = m_chartData;
newData[loc + "_daily"] = points;
m_chartData = newData;          // 替换整个 map
emit chartDataChanged();
```

---

### 4.5 AirQualityStore — 空气质量数据层

**文件**: `AirQualityStore.h/.cpp`（43+106 行）
**父类**: `QObject`

#### 类职责

管理空气质量数据，优先使用 US-EPA 标准 AQI。

#### Q_PROPERTY

| 属性 | 类型 | 说明 |
|------|------|------|
| `cities` | QVariantList | 城市列表 |
| `airData` | QVariantMap | `{cityId: {aqi, level, category, primaryPollutant, color, pollutants[]}}`

#### key 方法

| 方法 | 说明 |
|------|------|
| `setCities(cities)` | → refreshAll |
| `refreshAll()` | 遍历前 4 个城市，调用 `airCurrent(lat, lon, id)` |
| `onAirCurrentReady(cityId, result)` | 解析 AQI 索引（US-EPA 优先）、污染物列表、颜色值 |

**AQI 索引选择逻辑**:
```cpp
for (const QJsonValue& v : indexes) {
    if (idx["code"].toString() == "us-epa") { bestIndex = idx; break; }
}
// 若无 US-EPA，取第一个
```

---

### 4.6 SolarAstronomyStore — 太阳/天文数据层

**文件**: `SolarAstronomyStore.h/.cpp`（52+171 行）
**父类**: `QObject`

#### 类职责

合并 3 路 API（太阳辐射 + 日出日落 + 月相）结果到统一数据 map。

**中间累积缓冲**: `m_solarRaw[cityId] = { solar: {...}, sun: {...}, moon: {...} }`

**最终数据**: `m_solarData[cityId] = { ghi, dni, dhi, sunrise, sunset, moonPhase, ... }`

#### 架构

```
refreshAll() 触发 3 个 API 调用
    ↓
onSolarRadiationReady → 写入 m_solarRaw[cityId]["solar"] → mergeAndEmit
onAstronomySunReady   → 写入 m_solarRaw[cityId]["sun"]   → mergeAndEmit
onAstronomyMoonReady  → 写入 m_solarRaw[cityId]["moon"]  → mergeAndEmit
    ↓
mergeAndEmit(cityId) 合并三路数据 → 写入 m_solarData → emit solarDataChanged()
```

**关键信号连接**:
```cpp
connect(m_appSettings, &AppSettings::showSolarRadiationChanged, this, [this]() {
    refreshAll();          // 设置变化时重新加载
    emit solarDataChanged();
});
```

---

### 4.7 CityDetailStore — 城市详情聚合层

**文件**: `CityDetailStore.h/.cpp`（55+369 行）
**父类**: `QObject`

#### 类职责

最大的数据层，并行拉取 10 路 API，将所有数据合并到一个 `QVariantMap` 中。

#### `setCity(cityId, cityName, lat, lon)` 调用链

```
setCity()
  → 清除旧数据
  → 预初始化 10 个数据段为空对象
  → emit hasCityChanged() + detailChanged()
  → fetchAll()
```

#### `fetchAll()` — 并行发起 10 个 API 请求

```cpp
m_api->weatherNow(cityId);                   // 1. 实时天气
m_api->weatherDaily("3d", cityId);            // 2. 3日预报
m_api->weatherHourly("24h", cityId);          // 3. 24小时预报
m_api->indices("1d", "1-16", cityId);         // 4. 生活指数
m_api->astronomySun(cityId, today, cityId);   // 5. 日出日落
m_api->astronomyMoon(cityId, today, cityId);  // 6. 月相
m_api->airCurrent(lat, lon, cityId);          // 7. 空气质量
m_api->warningNow(lat, lon);                  // 8. 天气预警
m_api->solarRadiation(lat, lon, cityId);      // 9. 太阳辐射
m_api->minutelyPrecip(lat+","+lon);           // 10. 分钟降水
```

**预初始化保护**: 每个数据段在 `setCity` 时预初始化为空 QVariantMap/List，防止 QML 访问未定义属性时抛出 TypeError：

```cpp
m_detail["now"] = QVariantMap();
m_detail["daily"] = QVariantList();
// ... 10 个数据段
```

**写时复制模式**: 每次 handler 更新 `m_detail` 都创建新对象：
```cpp
QVariantMap dm = m_detail; dm["now"] = now; m_detail = dm;
emit detailChanged();
```

**Location 过滤**: 每个 handler 通过 `_location` 字段验证数据是否匹配当前城市：
```cpp
if (obj["_location"].toString() != m_cityId) return;
```

---

### 4.8 AppSettings — 应用设置

**文件**: `AppSettings.h/.cpp`（63+33 行）
**父类**: `QObject`

#### 持久化设置

通过 `QSettings`（注册表/INI 文件）持久化。

| 属性 | 默认值 | 说明 |
|------|--------|------|
| `darkMode` | true | 暗色模式 |
| `showSolarRadiation` | true | 太阳辐射显示 |
| `maxCards` | 4 | 最大卡片数（2-8） |

**主题颜色令牌**（由 `darkMode` 派生，只读）：

| 令牌 | 暗色模式 | 亮色模式 |
|------|----------|----------|
| `iconColor` | `#ffffff` | `#1a1a1a` |
| `textPrimary` | `#ffffff` | `#1a1a1a` |
| `textSecondary` | `#ccffffff` | `#4a4a4a` |
| `cardBg` | `#20ffffff` | `#20000000` |
| `accentColor` | `#4caf50` | `#4caf50`（不变） |

**设计细节**: 强调色 `#4caf50` 在所有天气类型下保持高对比度，是界面中唯一不受天气背景影响的颜色。

---

## 5. V3 天空模拟系统（C++）

这是项目的核心创新：一套基于 GPU 着色器的动态天空渲染系统。

### 5.1 GlobalClock — 全局时间源

**文件**: `GlobalClock.h/.cpp`（33+48 行）
**父类**: `QObject`

#### 类职责

提供全局统一的 60fps 时间源，为着色器动画提供 `elapsed` 时间值。

#### 关键成员

| 成员 | 类型 | 说明 |
|------|------|------|
| `m_timer` | QTimer | 16ms 间隔（约 60fps），`Qt::PreciseTimer` |
| `m_elapsedTimer` | QElapsedTimer | 高精度计时器 |
| `m_elapsed` | double | 累计运行秒数 |
| `m_pauseOffset` | double | 暂停时的时间偏移（用于恢复时继续计时） |

#### 函数流程

```
start()
  → m_elapsedTimer.start()
  → m_timer.start(16ms)
  → m_running = true

onTick() [每 16ms 调用]
  → secs = m_pauseOffset + m_elapsedTimer.elapsed() / 1000.0
  → if (changed) { m_elapsed = secs; emit tick(); }

stop()
  → m_timer.stop()
  → m_pauseOffset = m_elapsed
  → m_running = false

reset()
  → m_elapsed = 0
  → m_pauseOffset = 0
```

**QML 绑定**: `globalClock.elapsed` 绑定到各 ShaderEffect 的 `time` 属性。

---

### 5.2 AstronomyModel — 太阳/月亮位置计算

**文件**: `AstronomyModel.h/.cpp`（62+150 行）
**父类**: `QObject`

#### 类职责

基于经纬度 + 日出日落时间的简化天文公式，计算太阳/月亮位置。

#### 输入

| 方法 | 说明 |
|------|------|
| `setLocation(lat, lon)` | 设置经纬度，计算经度时区偏移 |
| `setSunTimes(sunrise, sunset)` | 设置日出日落时间（ISO 格式或 HH:mm） |
| `setMoonData(phaseIcon, illumination)` | 设置月相数据（来自和风 API） |
| `update(nowMsecs)` | 基于 UTC 时间更新计算 |
| `updateByMinute(minuteOfDay)` | Debug 模式：按分钟设时间 |

#### 输出（Q_PROPERTY 只读）

| 属性 | 说明 |
|------|------|
| `solarAltitude` | 太阳高度角（-90° ~ 90°） |
| `solarAzimuth` | 太阳方位角（0° ~ 360°） |
| `moonAltitude` | 月亮高度角 |
| `moonAzimuth` | 月亮方位角 |
| `moonPhase` | 月相（0~8，0=朔，4=望） |
| `moonIllum` | 月面亮度（0~1） |

#### 派生值

| 方法 | 说明 |
|------|------|
| `sunProgress()` | 0=日出，0.5=正午，1=日落（clamp 0~1） |
| `dayProgress()` | 同上，但无 clamp（用于夜间颜色插值） |
| `isNight()` | `currentMin < sunriseMin || currentMin > sunsetMin` |
| `currentMin()` | 当前分钟数（0~1439） |

#### `calcSolarPosition(dayOfYear, minuteOfDay)` — 核心算法

使用简化天文公式计算太阳位置：

```cpp
// 1. 太阳赤纬（23.45° 轴倾角）
declination = 23.45 * sin(2π * (dayOfYear - 81) / 365)

// 2. 时角（正午为 0°）
hourAngle = (minuteOfDay - 720) * 0.25°  // 每分钟 0.25°

// 3. 太阳高度角
sinAlt = sin(lat)*sin(declination) + cos(lat)*cos(declination)*cos(hourAngle)
solarAltitude = asin(sinAlt)  // 弧度转角度

// 4. 太阳方位角
cosAz = (sin(declination) - sin(lat)*sinAlt) / (cos(lat)*cos(asin(sinAlt)))
solarAzimuth = acos(cosAz)
if (hourAngle > 0) solarAzimuth = 360 - solarAzimuth  // 下午偏西
```

**月亮位置简化**: 取太阳对跖点偏移 180°，再加 15° 偏移：
```cpp
moonAltitude = clamp(-90, -solarAltitude + 15, 90);
moonAzimuth = (solarAzimuth + 180) % 360;
```

---

### 5.3 WeatherProfile — 天气码配置数据库

**文件**: `WeatherProfile.h/.cpp`（43+185 行）

#### WeatherProfile 结构体

| 字段 | 类型 | 说明 |
|------|------|------|
| `weatherParticle` | QString | 粒子类型: ""/"rain"/"snow" |
| `intensity` | float | 粒子强度 (0~1) |
| `weatherVariant` | int | 天气变体: 0=普通,1=雷暴,2=冰雹,3=雷暴+冰雹 |
| `cloudActive` | bool | 是否有云 |
| `cloudCoverage` | float | 云覆盖率 (0~1) |
| `cloudVariant` | int | 云变体: 0=少云,1=多云,2=阴 |
| `fogActive` | bool | 是否有雾 |
| `fogIntensity` | float | 雾密度 (0~1) |
| `fogVariant` | int | 雾变体: 0=雾,1=霾,2=沙尘 |
| `lightningActive` | bool | 是否有闪电 |
| `exposureOffset` | float | 曝光偏移 (-1~1) |

#### WeatherProfileDB 类

**68 个默认映射**（`initProfiles()` 中硬编码），按天气码分组：

| 码段 | 范围 | 示例 |
|------|------|------|
| 晴天 | 100-104 | 100=晴(无云), 104=阴(云100%) |
| 雨 | 300-399 | 300=阵雨, 302=雷阵雨, 308=极端降雨 |
| 雪 | 400-499 | 400=小雪, 403=暴雪 |
| 雾/霾/沙尘 | 500-515 | 500=薄雾, 503=扬沙 |
| 夜间覆盖 | 150-457 | 150-153=夜间晴, 350=夜间阵雨 |

#### 序列化

| 方法 | 说明 |
|------|------|
| `toJson()` | WeatherProfile → QJsonObject |
| `fromJson(o)` | QJsonObject → WeatherProfile |
| `loadFromFile(path)` | 从 `weather_profiles.json` 加载覆盖 |
| `saveToFile(path)` | 保存到 `weather_profiles.json` |

**查找逻辑**:
```cpp
WeatherProfile fromCode(int iconCode, bool isDay) {
    if (!isDay && nightOverrides.contains(iconCode))
        return nightOverrides[iconCode];   // 夜间覆盖优先
    if (dayProfiles.contains(iconCode))
        return dayProfiles[iconCode];
    return { sunny };                       // 默认晴天
}
```

---

### 5.4 BackgroundManager — 天空系统中央控制器

**文件**: `BackgroundManager.h/.cpp`（91+397 行）
**父类**: `QObject`

#### 类职责

天空模拟系统的中央控制器。连接 API 数据→SkyState，管理天文定时器，处理位置插值过渡，实现 7 段大气颜色模型。

#### Q_PROPERTY

| 属性 | 说明 |
|------|------|
| `skyState` | SkyState，当前完整天空状态 |
| `controlMode` | 0=自动, 1=调试 |
| `currentWeatherCode` | 当前天气码 |
| `currentIsDay` | 当前是否白天 |
| `currentLocalTime` | 本地时间字符串 |
| `configPath` | 配置文件路径（只读） |

#### 核心函数

| Q_INVOKABLE | 说明 |
|-------------|------|
| `commitSkyState(changes)` | 统一状态提交入口 |
| `updateWeather(iconCode)` | 根据天气码更新天空状态（昼夜由天文模型判断） |
| `updateSunTimes(sunrise, sunset)` | 更新日出日落 |
| `updateMoonData(phaseIcon, illum)` | 更新月相数据 |
| `setLocation(lat, lon)` | 切换城市（含插值过渡） |
| `enterDebugMode()` | 进入调试模式 |
| `setDebugTime(hour)` | 调试时间控制 |
| `saveProfileForCode(code)` | 保存当前调校为配置 |

---

#### `commitSkyState(changes)` — 统一状态提交入口

接受 `QVariantMap`，通过 3 个 lambda 解析器更新 SkyState 各字段：

```cpp
auto applyFloat = [&](const char *key, float &member, float min, float max);
auto applyInt   = [&](const char *key, int &member, int min, int max);
auto applyColor = [&](const char *key, QColor &member);
```

更新后调用 `TransitionController::setSkyState()` 并发射 `skyStateChanged()`。

---

#### `updateWeather(iconCode)` — 天气码到渲染参数的完整映射

```
bool isNight = m_astronomy.isNight();
WeatherProfile p = m_profiles.fromCode(iconCode, !isNight)
    ↓
starVisibility = isNight ? 0.8 : 0.0     ← 昼夜由天文模型判断
    ↓
计算曝光缩放因子:
  cloudDim = 1 - 0.45 * cloudCoverage
  rainDim  = 1 - 0.45 * rainIntensity
  snowDim  = 1 - 0.25 * snowIntensity
  fogDim   = 1 - 0.35 * fogIntensity
  weatherScale = max(0.15, cloudDim * rainDim * snowDim * fogDim)
    ↓
exposure = baseExposure * weatherScale + exposureOffset
    ↓
buildAtmosphereChanges()  ← 根据 dayProgress 计算大气颜色
    ↓
commitSkyState({cloudCoverage, rainIntensity, fogDensity, lightningProb,
                starVisibility, exposure, ...})
```

---

#### `buildAtmosphereChanges()` — 7 段大气颜色模型

根据 `AstronomyModel::dayProgress()` 值在 7 个颜色段之间插值：

| 段 | dayProgress | 天顶色 | 地平线色 | 环境色 |
|---|-----------|--------|----------|--------|
| deep night | < -0.30 | #0a0a1a | #0d0d28 | #050510 |
| blue hour | -0.30 ∼ 0.00 | #1a2a5a | #4a3060 | #0a0a20 |
| gold hour | 0.00 ∼ 0.15 | #4a6fa5 | #f4a460 | #e07050 |
| day | 0.15 ∼ 0.70 | #4a90d9 | #87ceeb | #c8e0f0 |
| warm noon | 0.70 ∼ 0.90 | #5a8ab5 | #d4996a | #c0b0a0 |
| orange | 0.90 ∼ 1.00 | #3a5a8a | #e07840 | #a03030 |
| purple | > 1.00 | #2a1a4a | #602040 | #0a0a20 |

**曝光/星星/黄昏因子的分段计算**:
```
dp < 0      (夜晚)  : exposure=0.3~0.6, starVis=0.2~0.8
0 < dp < 0.15 (黎明) : exposure=0.6~1.6, twilight=1~0, starVis=0.8~0
0.15~0.9    (白天)  : exposure=1.5~1.6, starVis=0
0.9~1.0     (黄昏)  : exposure=1.6~0.6, twilight=0~1, starVis=0~0.8
dp > 1.0    (夜晚)  : exposure=0.3~0.6, starVis=0.2~0.8
```

---

#### `setLocation(lat, lon)` — 位置插值过渡

当切换城市时，使用 60 帧的 smoothstep 插值过渡：

```
save m_lerpFrom = [当前 solarAltitude, solarAzimuth, moonAltitude, moonAzimuth]
    ↓
m_astronomy.setLocation(lat, lon)
m_astronomy.update(now)
    ↓
save m_lerpTo = [新的 solarAltitude, solarAzimuth, moonAltitude, moonAzimuth]
    ↓
buildAtmosphereChanges()  → 得到新的 starVisibility, twilightFactor, exposure, 颜色
    ↓
save m_lerpFrom[4,5] = [当前 starVisibility, twilightFactor]  (旧值)
save m_lerpTo[4,5]   = buildAtmosphereChanges 返回的新值
    ↓
立即提交大气颜色、曝光(× m_lastWeatherScale)、星光、黄昏因子
    ↓
m_lerpTick = 0
m_lerpTimer.start(16ms)
    ↓
tickLerp() [每 16ms]:
  t = tick / 60
  t = t²(3-2t)  // smoothstep
  // 线性插值 6 个字段: solarAltitude, solarAzimuth, moonAltitude,
  //                    moonAzimuth, starVisibility, twilightFactor
  commitSkyState(changes)
  if (t >= 1.0) stop timer
```

> **注意**：`starVisibility` 和 `twilightFactor` 的 lerp 目标值必须在 `buildAtmosphereChanges()` 之后捕获，否则 lerp 会用旧快照覆盖正确的新值。

#### `setLocation` 中曝光计算的注意事项

`setLocation` 提交的曝光值需要叠加天气压暗因子（`m_lastWeatherScale`），否则切换城市时曝光会短暂跳变为晴天基础值，随后才被 `updateWeather` 修正为正确的压暗值：

```cpp
// setLocation 中
ch["exposure"] = atm["exposure"].toDouble() * m_lastWeatherScale;

// updateSunTimes、onAstronomyTimer 中也有同样的乘法
ch["exposure"] = baseExp * m_lastWeatherScale;
```

初始值 `m_lastWeatherScale = 1.0f`（晴天无压暗），首次加载时不影响。

---

#### `onAstronomyTimer()` — 每分钟自动更新

每分钟调用一次，更新天文位置并重新计算大气颜色：

```cpp
m_astronomy.update(now);
QVariantMap ch = buildAstronomyChanges();
QVariantMap atmos = buildAtmosphereChanges();
ch.insert(atmos);
ch["exposure"] = ch["exposure"] * m_lastWeatherScale;
commitSkyState(ch);
```

---

### 5.5 TransitionController — 图层过渡编排器

**文件**: `TransitionController.h/.cpp`（97+307 行）
**父类**: `QObject`

#### 类职责

控制天气背景各图层的激活/去激活状态和过渡进度（transitionProgress）。实现防抖、延迟激活、Behavior 动画协调。

#### Q_PROPERTY

| 属性 | 说明 |
|------|------|
| `cloudActive` | 云层是否激活 |
| `weatherActive` | 天气层（雨/雪）是否激活 |
| `fogActive` | 雾层是否激活 |
| `lightningActive` | 闪电层是否激活 |
| `cloudTP / weatherTP / fogTP` | 各层过渡进度 (0~1) |
| `debugCloudTP / debugWeatherTP / debugFogTP` | Debug tp 覆盖 (0=自动) |
| `fadeInEnabled` | 是否启用淡入动画 |

#### `setSkyState(newState)` — 核心编排逻辑

每次 `BackgroundManager::commitSkyState` 时调用，判断各层是否应该激活/去激活：

```
m_transitionId++  // 增加版本号，防抖

Cloud 层:
  if cloudCoverage > 0.015 且之前 ≤ 0.005 → activateLayer("cloud", delay=100ms)
  if cloudCoverage ≤ 0.005 且之前 > 0.015 → deactivateLayer("cloud", duration=600ms)

Weather 层:
  if (rain+snow) > 0.015 且之前 ≤ 0.005 → activateLayer("weather", delay=400ms 如果云活跃, 否则 100ms)
  if (rain+snow) ≤ 0.005 且之前 > 0.015 → deactivateLayer("weather", duration=600ms)

Fog 层:
  if fogDensity > 0.015 且之前 ≤ 0.005 → activateLayer("fog", delay=100ms)
  if fogDensity ≤ 0.005 且之前 > 0.015 → deactivateLayer("fog", duration=400ms)

Lightning 层:
  if lightningProb > 0 → active=true
  else → active=false
```

**迟滞阈值**: 激活阈值 (`kActivate = 0.015`) > 去激活阈值 (`kDeactivate = 0.005`)，防止快速振荡。

---

#### `activateLayer()` — 激活时序

```
if (debugOverride >= 0):
  → 即时激活，tp=debugOverride
  → return

if (fadeInEnabled && delay > 0):
  → QTimer::singleShot(delay):          // 延迟后创建组件
      active = true
      emit activeChanged()
      → QTimer::singleShot(16ms):        // 下一帧设 tp=1
          tp = 1.0
          emit tpChanged()               // 触发 Behavior 动画
else:
  → 即时激活: active=true, tp=1.0
```

**延迟激活时序示例（云层，100ms 延迟，600ms 动画）**:
```
t=0ms:    backgroundManager.updateWeather(icon)  → cloudCoverage=0.6
         → TransitionController::setSkyState()
         → 匹配激活条件
t=100ms:  QTimer 触发 → cloudActive=true → Loader 加载 CloudLayer
         → tp=0（组件透明度=0）
t=116ms:  QTimer 触发 → tp=1 → Behavior 开始 600ms 动画
t=716ms:  tp 动画完成，云层完全显示
```

---

#### `deactivateLayer()` — 去激活时序

```
tp = 0                       // 触发 Behavior 淡出动画
emit tpChanged()
    ↓
QTimer::singleShot(duration):  // 等动画播完
  active = false             // Loader 销毁组件
  emit activeChanged()
```

---

## 6. QML 前端

### 6.1 Main.qml — 主应用窗口

**文件**: `Main.qml`（444 行）

#### 作用

主窗口、导航路由、城市列表管理、数据持久化、信号中枢。

#### 布局结构

```
ApplicationWindow (960×640)
  ├── WeatherBackground (z:-1)    ← 动态天空背景层
  ├── Rectangle (z:0)            ← 暗色遮罩（基于 exposure 动态不透明度）
  ├── WeatherBackgroundDebugPanel (z:100)
  └── MouseArea (parallax)
       └── RowLayout
            ├── Rectangle (侧边栏)
            │    ├── Logo (可折叠 QWeather/Q)
            │    ├── NavButton × 4 (仪表盘/天气预报/空气质量/天文)
            │    ├── Flickable → NavButton (固定城市)
            │    └── NavButton × 2 (收藏/设置)
            └── StackLayout (页面区，交叉淡入淡出)
                 ├── DashboardPage      (idx=0)
                 ├── ForecastPage       (idx=1)
                 ├── AirQualityPage     (idx=2)
                 ├── SolarAstronomyPage (idx=3)
                 ├── SettingsPage       (idx=4)
                 ├── CityDetailPage     (idx=5)
                 └── FavoritesPage      (idx=6)
```

#### 城市列表管理（栈操作）

```javascript
cityList = [focusCity, card1, card2, ...]
// 前 4 个城市自动同步到 ForecastStore/AirQualityStore/SolarAstronomyStore
```

| 函数 | 说明 |
|------|------|
| `promoteCity(id, name, lat, lon)` | 将城市提升到栈顶（若已存在则移除再插入），长度限制 maxCards+1 |
| `removeCity(id)` | 移除城市，若移除的是焦点城市则自动选择下一个 |
| `addFocus(id, name, lat, lon)` | 添加焦点城市 → promoteCity |
| `findCity(id)` | 在所有列表（cityList/favorites/pinned/history）中查找城市 |

#### 侧边栏城市显示逻辑

```javascript
sidebarCityId:
  if pinned.length > 0     → pinned[0].id
  else if favorites > 0    → favorites[0].id
  else if history > 0      → history[0].id
  else                     → focusId || ""
```

#### 焦点变更处理

```javascript
onFocusIdChanged:
  → addHistoryEntry(focusId)
  → weatherApi.weatherNow(focusId)
  → weatherApi.astronomySun(focusId, today)
  → weatherApi.astronomyMoon(focusId, today)
  → cityDetailStore.setCity(top, name, lat, lon)
  → backgroundManager.setLocation(lat, lon) [如果有经纬度]
```

#### 信号连接

```javascript
Connections {
    target: weatherApi
    onCityTopReady:         // 初始加载热门城市填充 cityList
    onWeatherNowReady:      // 更新 weathers 对象 + 调用 backgroundManager.updateWeather
    onAstronomySunReady:    // 调用 backgroundManager.updateSunTimes
    onAstronomyMoonReady:   // 调用 backgroundManager.updateMoonData
}
```

#### 视差效果

通过 `parallaxArea` 的 `onPositionChanged` 将鼠标位置映射到 -1~1 范围，传递给 WeatherBackground。

#### 暗色遮罩

```javascript
opacity = max(0, min((exposure - 1.2) / 0.6, 1.0)) * 0.2
// 低曝光（夜晚）→ 遮罩为 0
// 高曝光（白天）→ 遮罩最多 0.2，降低背景干扰
```

---

### 6.2 页面组件

#### DashboardPage.qml（97 行）

**功能**: 搜索城市 + 焦点城市大标题 + 天气信息 + 城市卡片网格

**组件**:
- `SearchBar`: 城市搜索（带防抖、键盘导航）
- `Text`: 焦点城市名（48px，双击跳转详情）
- `Text`: 天气描述 + 温度
- `Row` → `CityCard` × N: 城市卡片网格（cityList.slice(1)）

**双击检测**: 400ms 内连续单击两次为双击 → `navigateToDetail`

#### ForecastPage.qml（89 行）

**功能**: 预报范围选择器 + 2×2 预报卡片网格

**范围选择器**: 8 个选项: 24h/72h/168h/3d/7d/10d/15d/30d

**模式判断**:
```javascript
mode = forecastStore.mode  // "hourly" (含h) 或 "daily"
```

**卡片**: `ForecastCard` × 4

#### ForecastCard.qml（171 行）

**功能**: Qt Charts 温度曲线

**数据绑定**:
```javascript
points = forecastStore.chartData[cityId + "_" + mode]
info   = forecastStore.chartData[cityId + "_info"]
```

**图标配置**:
- 3 个预声明 Series（避免运行时创建导致的 NaN 轴问题）:
  - `SplineSeries` (气温/湿度)
  - `LineSeries` (最高温, 橙色 `#ff5252`)
  - `LineSeries` (最低温, 蓝色 `#448aff`)

**updateChart()**:
```
1. 遍历 points 计算 yMin/yMax
2. 设置 axisX (0~n-1), axisY (yMin~yMax)
3. 清空所有 series
4. 根据 mode 填充对应 series:
   - hourly: SplineSeries.append(i, point.y)
   - daily:  LineSeries(max).append(i, point.yMax)
             LineSeries(min).append(i, point.yMin)
```

#### AirQualityPage.qml（42 行）

**功能**: 2×2 AQI 卡片网格

#### AirQualityCard.qml（132 行）

**显示**:
- 彩色圆点 + AQI 大数字
- 类别名称
- 首要污染物
- 污染物浓度网格（2 列）

#### SolarAstronomyPage.qml（43 行）

**功能**: 2×2 太阳/天文卡片网格

#### SolarAstronomyCard.qml（171 行）

**显示**:
- GHI 大数字 + 单位
- DNI / DHI 副行
- 日出/日落时间
- 月相名称 + 月面亮度

#### SettingsPage.qml（356 行）

**功能**: 5 个设置卡片

1. **黑夜模式**: 切换开关
2. **最大卡片数**: -/+ 按钮（2~8）
3. **太阳辐射显示**: 切换开关（注释: "和风天气太阳辐射 API 无免费额度"）
4. **缓存管理**: 清除按钮
5. **版本**: v0.1

#### CityDetailPage.qml（633 行）

**功能**: 城市详情页，9 个信息卡片垂直排列

| 卡片 | 数据源 | 可见条件 |
|------|--------|----------|
| 实时天气 | `detail.now` | `!!temp` |
| 空气质量 | `detail.air` | `!!aqi` |
| 3 日预报 | `detail.daily` | `length > 0` |
| 24 小时预报 | `detail.hourly` | `length > 0` |
| 生活指数 | `detail.indices` | `length > 0` |
| 天气预警 | `detail.warnings` | `length > 0` |
| 天文 | `detail.sun/moon` | `!!sunrise || !!moonPhase` |
| 太阳辐射 | `detail.solar` | `ghi !== undefined` |
| 分钟降水 | `detail.minutely` | `!!summary` |

**内联组件**: `component DetailChip` — 标签-值小标签

#### FavoritesPage.qml（173 行）

**功能**: 收藏城市列表

**交互**:
- 单击: 切换焦点城市
- 双击: 跳转城市详情
- 图钉按钮: 固定/取消固定到侧边栏

---

### 6.3 天空系统 QML 组件

#### WeatherBackground.qml（144 行）

**功能**: 图层栈容器

**架构**（z-order 从底到顶）:
```
Item (bgRoot)
  ├── SkyLayer (z:0)        ← 始终渲染，无 Behavior
  ├── AtmosphereLayer (z:10) ← 始终渲染，无 Behavior
  ├── Loader (z:20)         ← CloudLayer（条件激活）
  ├── Loader (z:30)         ← RainLayer + SnowLayer（条件激活）
  ├── Loader (z:40)         ← FogLayer（条件激活）
  └── Loader (z:50)         ← LightningLayer（条件激活）
```

**关键特性**:
- 使用 `Loader.active` 绑定 `transitionCtrl.xxxActive` 实现条件加载
- 使用 `Behavior on opacity { NumberAnimation }` 实现淡入淡出
- `SkyLayer` 和 `AtmosphereLayer` 始终渲染（无 Loader）
- Parallax 视差从 `bgRoot.parallaxX/Y` 属性传递

**Weather 层的特殊处理**: 用一个 Component 包裹 RainLayer + SnowLayer，通过 `visible` 属性控制可见性（共享 Loader 的 active 信号）：

```qml
Component {
    id: weatherComp
    Item {
        RainLayer { visible: rainIntensity > 0.001 }
        SnowLayer { visible: snowIntensity > 0.001 }
    }
}
```

#### SkyLayer.qml（53 行）

**ShaderEffect** 绑定 `qrc:/shaders/sky.frag.qsb`

**属性**（15 个 + 视差）:
- `time`, `solarAltitude`, `solarAzimuth`, `moonAltitude`, `moonAzimuth`, `moonPhase`, `moonIllum`
- `zenithColor`, `horizonColor`, `ambientColor`, `exposure`, `twilightFactor`
- `starVisibility`, `parallaxX`, `parallaxY`

**Behavior 动画（800ms）**: `zenithColor`, `horizonColor`, `ambientColor`, `exposure`

#### AtmosphereLayer.qml（37 行）

**ShaderEffect** 绑定 `qrc:/shaders/atmosphere.frag.qsb`

**属性**: `time`, `zenithColor`, `horizonColor`, `ambientColor`, `exposure`, `twilightFactor`

**Behavior 动画（800ms）**: 颜色属性

#### CloudLayer.qml（39 行）

**ShaderEffect** 绑定 `qrc:/shaders/cloud.frag.qsb`

**属性**: `time`, `cloudCoverage`, `cloudOpacity`, `variant`, `windSpeed`, `transitionProgress`, `exposure`

**Behavior 动画**: `transitionProgress`（600ms）, `cloudCoverage`（400ms 或 0ms 根据 fadeInEnabled）

#### RainLayer.qml（42 行）

**ShaderEffect** 绑定 `qrc:/shaders/rain.frag.qsb`

**属性**: `time`, `intensity`, `variant`, `windSpeed`, `transitionProgress`, `exposure`, `particleLimit`

#### SnowLayer.qml（41 行）

**ShaderEffect** 绑定 `qrc:/shaders/snow.frag.qsb`

**属性**: `time`, `intensity`, `variant`, `windSpeed`, `transitionProgress`, `particleLimit`

#### FogLayer.qml（40 行）

**ShaderEffect** 绑定 `qrc:/shaders/fog.frag.qsb`

**属性**: `time`, `intensity`, `variant`, `windSpeed`, `transitionProgress`

#### LightningLayer.qml（23 行）

**ShaderEffect** 绑定 `qrc:/shaders/lightning.frag.qsb`

**属性**: `time`, `lightningProb`

#### WeatherBackgroundDebugPanel.qml（659 行）

**功能**: 实时天空参数调校 UI

**快捷键**: `Ctrl+Shift+B` 打开/关闭

**功能模块**:
1. **模式切换**: Auto / Debug
2. **Layer 状态**: 5 个图层的激活状态 + tp 值显示
3. **过渡控制**: 云 tp / 天气 tp / 雾 tp 滑块、淡入开关
4. **时间控制**: 时间滑块 (0~24h)、太阳高度、本地时间、时段描述
5. **天气码模拟**: 输入 + 预设 ComboBox（42 种天气）+ 应用按钮
6. **天文参数**: 6 个滑块
7. **天气参数**: 云覆盖/雨强度/雪强度/雾密度/闪电/星星 + 3 个变体选择器 + 曝光 + 黄昏因子
8. **配置持久化**: 保存当前调校为天气码配置
9. **演示模式**: 自动演示（快速/完整）
10. **天空色**: 天顶/地平/环境色（循环切换预设）
11. **快捷操作**: 晴天/多云/下雨/夜晚 一键设置

**自动演示逻辑**:
```
Timer (50ms):
  tick++
  if wLerp < 40:           // 天气参数插值过渡
    lerp weather params
  demoHour += speed / 60   // 时间前进
  if demoHour >= 24: demoHour -= 24
  backgroundManager.setDebugTime(demoHour)
  if tick % interval === 0: // 切换天气码
    switchWeather(next)
```

---

### 6.4 可复用 UI 组件

#### NavButton.qml（98 行）

**功能**: 可折叠导航按钮

**状态**:
- 折叠（expanded=false）: 图标居中，宽度 64px
- 展开（expanded=true）: 图标+文字左对齐，宽度 184px

**图标着色**: `MultiEffect`（brightness=1.0, colorization=1.0）

**交互**:
- 悬停: `#20ffffff` 半透明背景
- 激活（active=true）: `#334caf50` 绿色背景
- 200ms `OutCubic` 动画

#### SearchBar.qml（336 行）

**功能**: 城市搜索（带防抖、键盘导航、弹出结果列表）

**架构**:
```
Rectangle (搜索框)
  → MouseArea: 点击打开 Popup
  → Popup:
      → TextField (输入, 300ms 防抖)
      → Rectangle (分隔线)
      → ListView (结果列表)
        → ItemDelegate × N (城市名 + 行政区域 + 国家)
          → 键盘: Up/Down 导航, Enter 选择
```

**防抖**: `Timer { interval: 300 }`，`onTextChanged` 时重启

**API 过滤**: `onCityLookupReady` 回调时检查 `_pendingSearch === input.text`，防止过时响应

#### WeatherIcon.qml（59 行）

**功能**: 和风天气图标组件

**图标映射**: 天气码→SVG URL（`https://icons.qweather.com/assets/icons/{code}.svg`）

**图标着色**: `MultiEffect`（与 NavButton 相同的着色方案）

#### CityCard.qml（108 行）

**功能**: 城市信息卡片

**交互**:
- 单击（400ms 超时）: `clicked(cityId)` → 切换焦点
- 双击（400ms 内）: `doubleClicked(cityId)` → 跳转详情
- 悬停显示关闭按钮

**双击检测**:
```javascript
property var _lastClickTime: 0
Timer { id: clickTimer; interval: 400 }

onClicked:
  now - _lastClickTime < 400 ? doubleClicked : start timer
```

#### InfoChip.qml（28 行）

**功能**: 标签-值数据芯片

**布局**: `Row { label + value }`

---

## 7. GLSL 着色器系统

### 7.1 着色器文件

#### sky.frag（148 行）— 天空渐变 + 太阳/月亮/星星

**技巧**: 内联所有函数（未使用 `#include`），避免 ShaderBaker 路径问题。

**渲染管线**:
```
1. 天空渐变: mix(zenithColor, horizonColor, pow(uv.y, 0.8))
2. 太阳光晕: exp(-dist² * 15 / glowSize²) × sunColor
3. 太阳核心: exp(-dist² * 200) × 白色
4. 低角度太阳颜色: mix(白黄, 橙红, lowAngle)
5. 月亮光晕: exp(-dist² × 10) × 蓝白 × 0.4
6. 月亮 SDF 月相裁剪
7. 星星: 50 个粒子，hash 位置 + 正弦闪烁
8. ACES 色调映射: (color×(2.51×color+0.03)) / (color×(2.43×color+0.59)+0.14)
```

**Uniform**（std140, binding=0）:
```
qt_Matrix, qt_Opacity, time, solarAltitude, solarAzimuth,
moonAltitude, moonAzimuth, moonPhase(0~8), moonIllum,
zenithColor, horizonColor, ambientColor, exposure,
twilightFactor, starVisibility, parallaxX, parallaxY
```

#### atmosphere.frag（40 行）— 黄昏散射光晕

**渲染**:
```
atmosColor = mix(zenith, horizon, pow(uv.y, 0.7))
 + twilightTint(1.0, 0.6, 0.3) × twilightFactor × 0.15
 mix(ambientColor, 0.1)
 × exposure
 alpha = 0.3
```

#### cloud.frag（145 行）— 体积云

**技术**: Inigo Quilez 动态云算法（3 层 fBM + 域扭曲 + 4 步光线步进）

**渲染管线**:
```
1. 过渡偏移: uv.x += (1 - tp) × 0.6  // 云从右侧滑入
2. 域扭曲: fbm 采样坐标 → warp 偏移
3. 3 层 fBM:
   layer1: uv×3 + warp + drift (3 个 octaves)
   layer2: uv×1.5 + warp×0.7 + drift (2 个 octaves) × 0.6
   layer3: uv×6 + warp×1.2 + drift (2 个 octaves) × 0.3
4. Emptiness/Sharpness 重映射 (Inigo Quilez):
   fill = cloudCoverage × densityScale
   emptiness = 0.30 × (1 - fill × 0.90)
   sharpness = 0.95 - fill × 0.55
   cloud = clamp((raw - emptiness) / (sharpness - emptiness), 0, 1)
5. 4 步光线步进:
   cloud = dot(max(cloud - vec4(base), 0), vec4(0.25))
6. 高度权重: variant=1 时集中在天空上部
7. 颜色: 白灰渐变，夜间变暗
```

**变体**:
- variant 0 (少云): densityScale=0.3, 无高度限制
- variant 1 (多云): densityScale=0.7, 集中在上部
- variant 2 (阴): densityScale=2.0, 全覆盖

#### rain.frag（105 行）— 基于网格的雨粒子

**技术**: 12 层网格粒子系统

**渲染管线**:
```
1. 过渡: activeIntensity = intensity × tp
2. 雨丝颜色: exposure 补偿
3. 12 层循环:
   - 按 scale / cellID 确定网格列
   - hash(cellID) > density 则跳过（稀疏控制）
   - 计算雨滴下落进度: fract(time × dropSpeed)
   - SDF 椭圆函数 sdEllipse() 绘制雨滴
   - 底部溅射涟漪
4. 曝光补偿: alpha *= clamp(exposure × 0.8, 0.6, 3.0)
```

#### snow.frag（82 行）— 雪花粒子

**技术**: 60 个雪花的粒子系统

**渲染管线**:
```
1. 60 次循环:
   - hash 位置、速度 (0.1~0.35)、摇摆 (sin×0.02)
   - 圆形 SDF 检测
   - alpha 累积
2. variant=1 (冻雨): blend blue tint 30%
3. alpha clamp(0, 0.6)
```

#### fog.frag（74 行）— 雾/霾/沙尘

**变体**:
- 0 (雾): 乳白色 `(0.85, 0.85, 0.88)`
- 1 (霾): 灰黄色 `(0.6, 0.55, 0.45)`
- 2 (沙尘): 土棕色 `(0.5, 0.4, 0.25)` + 颗粒噪声

**渲染**:
```
horizonFade = 1 - |uv.y - 0.5| × 1.2  // 地平线处更厚
heightFade = 1 - uv.y × 0.5           // 底部更厚
alpha = clamp(fogAlpha × horizonFade × heightFade, 0, 0.85)
```

#### lightning.frag（46 行）— 闪电闪烁

**技术**: 基于 epcoh（3 秒周期）+ hash 随机触发

**渲染**:
```
epoch = floor(time / 3.0)
hash = fract(sin(epoch × 127.1 + 311.7) × 43758.5453)
triggerTime = hash  // 0~1

// 第一次闪烁
dt = epochTime - triggerTime
flash = exp(-dt × 30)  // 快速衰减

// 第二次闪烁（200ms 后）
dt2 = epochTime - (triggerTime + 0.2/3.0)
flash = max(flash, exp(-dt2 × 40))

brightness = flash × 1.5 × lightningProb
```

---

### 7.2 通用 GLSL 库

所有库文件位于 `shaders/common/`，使用 `#ifndef` 防止重复包含。

#### math.glsl（25 行）

常量: `PI`, `TWO_PI`, `HALF_PI`, `DEG2RAD`, `RAD2DEG`

函数: `clamp01`, `map`, `lerp`(float/vec3), `smoothstep01`, `saturate`

#### random.glsl（64 行）

**哈希函数**:
- `hash1(float)` — 1D→1D
- `hash1(vec2)` — 2D→1D
- `hash2(vec2)` — 2D→2D
- `hash1(vec3)` — 3D→1D

**噪声函数**:
- `noise2D(vec2)` — 2D 值噪声（3 次 Hermite 插值）
- `noise3D(vec3)` — 3D 值噪声（三线性插值）

#### noise.glsl（37 行）

**fBM 函数**:
- `fbm2D(p, octaves)` — 多 octave 2D 分形布朗运动
- `fbm3D(p, octaves)` — 3D 版本
- `fbmWarp(p, octaves)` — 域扭曲 fBM（先 fbm 两次，再用结果偏移坐标再次 fbm）

#### color.glsl（28 行）

- `rgb2hsv(c)` — RGB→HSV 转换
- `hsv2rgb(c)` — HSV→RGB 转换
- `srgb2linear(c)` — sRGB→线性空间（pow 2.2）
- `linear2srgb(c)` — 线性→sRGB（pow 1/2.2）

#### lighting.glsl（52 行）

- `sunGlow(uv, pos, color, size)` — 高斯光晕
- `moonGlow(uv, pos, size)` — 月亮光晕（蓝白调）
- `moonPhaseSDF(uv, pos, radius, phase)` — 月相 SDF
- `starField(uv, time, visibility, density)` — 50 颗星 + 闪烁

#### particle.glsl（35 行）

- `rainDrop(uv, pos, length, width, time, seed)` — 雨滴 SDF
- `snowFlake(uv, pos, size, time, seed)` — 雪花 SDF
- `hailDrop(uv, pos, size, time, seed)` — 冰雹 SDF

#### tonemap.glsl（30 行）

- `uncharted2Tonemap(color)` — Uncharted 2 色调映射
- `acesTonemap(color)` — ACES 色调映射（sky.frag 内联使用）
- `applyExposure(color, exposure)` — 曝光 + ACES

---

## 8. 数据流与状态管理

### 8.1 数据流全景

```
[和风天气 API]
    ↓ HTTPS (QNetworkAccessManager)
[WeatherAPI]  ←→ [WeatherCache (SQLite)]
    ↓ 信号 (26 个 ready 信号)
[Store 层] (ForecastStore / AirQualityStore / SolarAstronomyStore / CityDetailStore)
    ↓ Q_PROPERTY (QVariantMap)
[QQmlApplicationEngine]
    ↓ 上下文属性
[QML View]
    ↓
[Main.qml 信号中枢]
    ↓
[BackgroundManager]  ←→ [TransitionController]
    ↓ Q_PROPERTY (SkyState)
[QML ShaderEffect 绑定]
    ↓ uniform (std140)
[GLSL Shader]
    ↓ GPU 渲染
[屏幕]
```

### 8.2 用户操作→渲染的完整路径

以"搜索并切换城市"为例：

```
1. 用户输入城市名 → SearchBar.onTextChanged
2. debounce(300ms) → weatherApi.searchCity(name)
3. WeatherAPI → HTTPS GET → 解析 JSON → emit cityLookupReady
4. Main.qml → onCityLookupReady → 填充结果列表
5. 用户点击城市 → SearchBar.selectCity → DashboardPage.onCitySelected
6. Main.qml → addFocus(id) → promoteCity(id)
7. promoteCity → cityList 更新 → onCityListChanged → 同步 3 个 Store
8. onFocusIdChanged → weatherNow / astronomySun / astronomyMoon 调用
9. CityDetailStore.setCity → fetchAll (10 个 API)
10. weatherNowReady → weathers[id] = {temp,icon,text}
    → backgroundManager.updateWeather(iconCode)
11. updateWeather → WeatherProfile.fromCode → 计算 exposure
    → commitSkyState({cloudCoverage, rainIntensity, ...})
12. commitSkyState → TransitionController.setSkyState
    → 判断各 Layer 是否激活 → 设置 tp 值
13. QML Loader → 激活/去激活 + Behavior 动画
14. ShaderEffect 属性绑定 → 更新 uniform
15. GPU 渲染新一帧
```

### 8.3 状态更新频率

| 更新源 | 频率 | 影响 |
|--------|------|------|
| GlobalClock.tick | 16ms (60fps) | 着色器 time uniform |
| BackgroundManager.astronomyTimer | 60000ms (1 分钟) | 天文位置、大气颜色 |
| TransitionController QTimer | 100-600ms (一次性) | 图层 tp 过渡 |
| QML Behavior 动画 | ~16ms 内插 | QML 属性 → ShaderEffect uniform |
| WeatherAPI → onReplyFinished | 用户操作后 0.5-3s | 天气数据刷新 |

---

## 9. CMakeLists.txt 构建配置详解

完整解析 `CMakeLists.txt`（104 行）：

### 9.1 项目配置

```cmake
cmake_minimum_required(VERSION 3.16)        # 最低 CMake 版本
project(qml1 VERSION 0.1 LANGUAGES CXX)     # 项目名 + 版本
set(CMAKE_CXX_STANDARD_REQUIRED ON)         # C++17 强制
```

### 9.2 依赖

```cmake
find_package(Qt6 REQUIRED COMPONENTS
    Quick Network Sql Charts Widgets ShaderTools
)
qt_standard_project_setup(REQUIRES 6.10)     # 最低 Qt 6.10
```

### 9.3 可选子目录

```cmake
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(importedcontent)         # Figma 导入内容（可选）
endif()
```

### 9.4 可执行体

```cmake
qt_add_executable(appqml1 main.cpp)
```

### 9.5 QML 模块

```cmake
qt_add_qml_module(appqml1
    URI qml1
    QML_FILES
        Main.qml
        DashboardPage.qml
        # ... 共 19 个 .qml 文件
    SOURCES
        AppSettings.h AppSettings.cpp
        weatherApi.h weatherApi.cpp
        WeatherCache.h WeatherCache.cpp
        ForecastStore.h ForecastStore.cpp
        AirQualityStore.h AirQualityStore.cpp
        SolarAstronomyStore.h SolarAstronomyStore.cpp
        CityDetailStore.h CityDetailStore.cpp
        GlobalClock.h GlobalClock.cpp
        WeatherProfile.h WeatherProfile.cpp
        AstronomyModel.h AstronomyModel.cpp
        SkyState.h
        BackgroundManager.h BackgroundManager.cpp
        TransitionController.h TransitionController.cpp
)
```

### 9.6 资源文件

```cmake
qt_add_resources(appqml1 "icons"
    PREFIX "/"
    FILES
        icons/squares-four.svg
        icons/calendar.svg
        # ... 共 7 个 SVG
)

qt_add_shaders(appqml1 "shaders"
    PREFIX "/"
    FILES
        shaders/sky.frag
        shaders/atmosphere.frag
        # ... 共 7 个 .frag
)
```

### 9.7 链接

```cmake
target_link_libraries(appqml1
    PRIVATE Qt6::Quick Qt6::Network Qt6::Sql Qt6::Charts Qt6::Widgets
)
```

---

> 文档结束。
>
> 本文档覆盖了 QWeather 项目中所有 C++ 类（14 个头文件 + 13 个源文件）、
> 所有 QML 组件（19 个文件）、所有 GLSL 着色器（7 个着色器 + 7 个通用库）、
> 以及构建系统的完整实现原理。
