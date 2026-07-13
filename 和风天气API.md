数据已基本收集齐全，以下是和风天气 API 的完整整理：

---

## 和风天气 API 完整整理 (功能 | 路径 | 参数)

### 一、GeoAPI（地理信息）

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 城市搜索 | `GET /geo/v2/city/lookup` | `location`（LocationID或"经度,纬度"） | `adm`, `range`(ISO 3166国家代码), `number`(1-20), `lang` |
| 热门城市查询 | `GET /geo/v2/city/top` | —   | `range`(ISO 3166), `number`(1-20), `lang` |
| POI搜索 | `GET /geo/v2/poi/lookup` | `location`, `type`（`scenic`景点/`TSTA`潮汐站） | `city`, `number`(1-20), `lang` |

### 二、天气预报

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 实时天气 | `GET /v7/weather/now` | `location` | `lang` |
| 每日天气预报 | `GET /v7/weather/{days}` | `days`路径(3d/7d/10d/15d/30d), `location` | `lang` |
| 逐小时天气预报 | `GET /v7/weather/{hours}` | `hours`路径(24h/72h/168h), `location` | `lang` |
| 格点实时天气 | `GET /v7/grid-weather/now` | `location`（仅坐标"经度,纬度"） | `lang`, `unit`(m/i) |
| 格点每日预报 | `GET /v7/grid-weather/{days}` | `days`路径(3d/7d), `location`（仅坐标） | `lang`, `unit`(m/i) |
| 格点逐小时预报 | `GET /v7/grid-weather/{hours}` | `hours`路径(24h/72h), `location`（仅坐标） | `lang`, `unit`(m/i) |

### 三、分钟预报

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 分钟级降水 | `GET /v7/minutely/5m` | `location`（仅坐标"经度,纬度"） | `lang` |

### 四、预警

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 实时天气预警（新版 v1） | `GET /weatheralert/v1/current/{lat}/{lng}` | `latitude`, `longitude`（路径参数） | `localTime`, `lang` |
| 天气预警（旧版，2026-10-01停止） | `GET /v7/warning/now` | `location` | `lang` |

### 五、天气指数

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 天气指数预报 | `GET /v7/indices/{days}` | `days`路径(1d/3d), `type`（指数ID，多值逗号分隔）, `location` | `lang` |

### 六、空气质量

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 实时空气质量 | `GET /airquality/v1/current/{lat}/{lng}` | `latitude`, `longitude`（路径参数） | —   |
| 空气质量小时预报 | `GET /airquality/v1/hourly/{lat}/{lng}` | `latitude`, `longitude`（路径参数） | `localTime`, `lang` |
| 空气质量每日预报 | `GET /airquality/v1/daily/{lat}/{lng}` | `latitude`, `longitude`（路径参数） | `localTime`, `lang` |
| 监测站数据 | `GET /airquality/v1/stations/{locationId}` | `locationId`（路径参数，如 P58911） | —   |

### 七、时光机（历史数据）

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 天气时光机 | `GET /v7/historical/weather` | `location`（仅LocationID）, `date`(yyyyMMdd, 近10天不含今日) | `lang`, `unit`(m/i) |
| 空气质量时光机 | `GET /v7/historical/air` | `location`（仅LocationID）, `date`(yyyyMMdd, 近10天不含今日) | `lang` |

### 八、热带气旋（台风）

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 台风列表 | `GET /v7/tropical/storm-list` | `basin`（流域代码：NP/AL/EP/SP/NI/SI） | `year` |
| 台风实况和路径 | `GET /v7/tropical/storm-track` | `stormid`（如 NP2018） | —   |
| 台风预报 | `GET /v7/tropical/storm-forecast` | `stormid`（如 NP2018） | —   |

### 九、海洋数据

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 潮汐  | `GET /v7/ocean/tide` | `location`（潮汐站ID，如 P66981）, `date`(yyyyMMdd) | —   |

### 十、太阳辐射

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 太阳辐射预报 | `GET /solarradiation/v1/forecast/{lat}/{lng}` | `latitude`, `longitude`（路径参数） | `hours`(1-60,默认24), `interval`(15/30/60), `tilt`(0-90), `azimuth`(0-359), `extra`(weather/poa), `localTime` |

### 十一、天文

| 功能  | 请求路径 | 必选参数 | 可选参数 |
| --- | --- | --- | --- |
| 日出日落 | `GET /v7/astronomy/sun` | `location`, `date`(yyyyMMdd) | —   |
| 月升月落和月相 | `GET /v7/astronomy/moon` | `location`, `date`(yyyyMMdd) | `lang` |
| 太阳高度角 | `GET /v7/astronomy/solar-elevation-angle` | `location`, `date`(yyyyMMdd), `time`(HHmm), `tz`(±HHMM), `alt`(米) | —   |

---

### 通用说明

-   **认证方式**：所有 API 通过 HTTP Header `Authorization: Bearer your_token` 进行 JWT 认证
    
-   **API Host**：根据不同订阅类型使用不同的 API 域名（如 `devapi.qweather.com` 或 `api.qweather.com`）
    
-   **响应格式**：JSON，支持 Gzip 压缩
    
-   **多语言**：通过 `lang` 参数设置（如 `zh`, `en` 等）
    
-   **注意**：`/v7/warning/now` 已标记为弃用，预计 **2026-10-01** 停止服务，应迁移到新版 `/weatheralert/v1/current/{lat}/{lng}`