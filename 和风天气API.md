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
-   

根据之前获取的所有 API 文档，以下是完整版（含返回格式）：

---

## 和风天气 API 完整整理 (功能 | 路径 | 参数 | 返回格式)

---

### 一、GeoAPI（地理信息）

#### 1\. 城市搜索

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /geo/v2/city/lookup` |
| **必选参数** | `location`（LocationID 或 "经度,纬度"） |
| **可选参数** | `adm`（上级行政区划）、`range`（ISO 3166 国家代码）、`number`（1-20，默认10）、`lang` |

**返回格式：**

```json
{
  "code": "200",
  "location": [
    {
      "name": "东城",
      "id": "101011600",
      "lat": "39.91755",
      "lon": "116.41876",
      "adm2": "北京",
      "adm1": "北京市",
      "country": "中国",
      "tz": "Asia/Shanghai",
      "utcOffset": "+08:00",
      "isDst": "0",
      "type": "city",
      "rank": "35",
      "fxLink": "https://www.qweather.com/..."
    }
  ]
}
```

| 关键字段 | `location[].id`(LocationID)、`location[].name`、`location[].lat/lon`、`location[].country` |

---

#### 2\. 热门城市查询

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /geo/v2/city/top` |
| **必选参数** | —   |
| **可选参数** | `range`（ISO 3166）、`number`（1-20）、`lang` |

**返回格式：** 同上，字段为 `topCityList[]`，结构与 `location[]` 相同

---

#### 3\. POI搜索

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /geo/v2/poi/lookup` |
| **必选参数** | `location`、`type`（`scenic`景点 / `TSTA`潮汐站） |
| **可选参数** | `city`、`number`（1-20）、`lang` |

**返回格式：**

```json
{
  "code": "200",
  "poi": [
    {
      "name": "景山公园",
      "id": "10101010012A",
      "lat": "39.91999",
      "lon": "116.38999",
      "adm2": "北京",
      "type": "scenic",
      "rank": "671"
    }
  ]
}
```

| 关键字段 | `poi[].id`、`poi[].name`、`poi[].type` |

---

### 二、天气预报（城市级别，基于观测站）

#### 4\. 实时天气

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/weather/now` |
| **必选参数** | `location`（LocationID 或 "经度,纬度"） |
| **可选参数** | `lang` |

**返回格式：**

```json
{
  "code": "200",
  "updateTime": "2020-06-30T22:00+08:00",
  "now": {
    "obsTime": "2020-06-30T21:40+08:00",
    "temp": "24",
    "feelsLike": "26",
    "icon": "101",
    "text": "多云",
    "wind360": "123",
    "windDir": "东南风",
    "windScale": "1",
    "windSpeed": "3",
    "humidity": "72",
    "precip": "0.0",
    "pressure": "1003",
    "vis": "16",
    "cloud": "10",
    "dew": "21"
  }
}
```

| 关键字段 | `now.temp`、`now.feelsLike`、`now.icon`、`now.text`、`now.windDir/Speed/Scale`、`now.humidity`、`now.pressure` |

---

#### 5\. 每日天气预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/weather/{days}` |
| **必选参数** | `days` 路径（`3d`/`7d`/`10d`/`15d`/`30d`）、`location` |
| **可选参数** | `lang` |

**返回格式：**

```json
{
  "code": "200",
  "updateTime": "2021-11-15T16:35+08:00",
  "daily": [
    {
      "fxDate": "2021-11-15",
      "sunrise": "06:58",
      "sunset": "16:59",
      "moonrise": "15:16",
      "moonset": "03:40",
      "moonPhase": "盈凸月",
      "moonPhaseIcon": "803",
      "tempMax": "12",
      "tempMin": "-1",
      "iconDay": "101",
      "textDay": "多云",
      "iconNight": "150",
      "textNight": "晴",
      "wind360Day": "45",
      "windDirDay": "东北风",
      "windScaleDay": "1-2",
      "windSpeedDay": "3",
      "wind360Night": "0",
      "windDirNight": "北风",
      "windScaleNight": "1-2",
      "windSpeedNight": "3",
      "humidity": "65",
      "precip": "0.0",
      "pressure": "1020",
      "vis": "25",
      "cloud": "4",
      "uvIndex": "3"
    }
  ]
}
```

| 关键字段 | `daily[].fxDate`、`tempMax/Min`、`sunrise/sunset`、`moonrise/moonset`、`iconDay/Night`、`textDay/Night`、`uvIndex` |

---

#### 6\. 逐小时天气预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/weather/{hours}` |
| **必选参数** | `hours` 路径（`24h`/`72h`/`168h`）、`location` |
| **可选参数** | `lang` |

**返回格式：**

```json
{
  "code": "200",
  "updateTime": "2021-02-16T13:35+08:00",
  "hourly": [
    {
      "fxTime": "2021-02-16T15:00+08:00",
      "temp": "2",
      "icon": "100",
      "text": "晴",
      "wind360": "335",
      "windDir": "西北风",
      "windScale": "3-4",
      "windSpeed": "20",
      "humidity": "11",
      "pop": "0",
      "precip": "0.0",
      "pressure": "1025",
      "cloud": "0",
      "dew": "-25"
    }
  ]
}
```

| 关键字段 | `hourly[].fxTime`、`temp`、`icon`、`text`、`pop`(降水概率)、`dew`(露点温度) |

---

### 三、格点天气预报（数值模型，坐标查询，UTC时间）

#### 7\. 格点实时天气

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/grid-weather/now` |
| **必选参数** | `location`（仅 "经度,纬度"） |
| **可选参数** | `lang`、`unit`（`m`公制 / `i`英制） |

**返回格式：** 与城市实时天气结构相同，`now{}` 对象包含 `obsTime`/`temp`/`icon`/`text`/`wind*`/`humidity`/`precip`/`pressure`/`cloud`/`dew`

---

#### 8\. 格点每日天气预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/grid-weather/{days}` |
| **必选参数** | `days` 路径（`3d`/`7d`）、`location`（仅坐标） |
| **可选参数** | `lang`、`unit`（`m`/`i`） |

**返回格式：** 与城市逐日预报结构相同，`daily[]` 包含 `fxDate`/`tempMax/Min`/`iconDay/Night`/`textDay/Night`/`wind*Day/Night`/`humidity`/`precip`/`pressure`（无 `sunrise/sunset`/`moonPhase`/`vis`/`uvIndex`）

---

#### 9\. 格点逐小时天气预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/grid-weather/{hours}` |
| **必选参数** | `hours` 路径（`24h`/`72h`）、`location`（仅坐标） |
| **可选参数** | `lang`、`unit`（`m`/`i`） |

**返回格式：** 与城市逐小时预报结构相同，`hourly[]` 包含 `fxTime`/`temp`/`icon`/`text`/`wind*`/`humidity`/`precip`/`pressure`/`cloud`/`dew`

---

### 四、分钟预报

#### 10\. 分钟级降水

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/minutely/5m` |
| **必选参数** | `location`（仅 "经度,纬度"） |
| **可选参数** | `lang` |

**返回格式：**

```json
{
  "code": "200",
  "updateTime": "2021-12-16T18:55+08:00",
  "summary": "95分钟后雨就停了",
  "minutely": [
    {
      "fxTime": "2021-12-16T18:55+08:00",
      "precip": "0.15",
      "type": "rain"
    }
  ]
}
```

| 关键字段 | `summary`（降水描述）、`minutely[].fxTime`、`minutely[].precip`(5分钟累计降水mm)、`minutely[].type`(rain/snow) |

---

### 五、预警

#### 11\. 实时天气预警（新版 v1，推荐）

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /weatheralert/v1/current/{latitude}/{longitude}` |
| **必选参数** | `latitude`、`longitude`（路径参数） |
| **可选参数** | `localTime`（true/false）、`lang` |

**返回格式：**

```json
{
  "metadata": {
    "tag": "ec71f87d...",
    "zeroResult": false
  },
  "alerts": [
    {
      "id": "202510241119105837988676",
      "senderName": "临桂区气象台",
      "issuedTime": "2025-10-24T11:19+08:00",
      "messageType": {
        "code": "update",
        "supersedes": ["202510181140100706230391"]
      },
      "eventType": {
        "name": "大风",
        "code": "1006"
      },
      "severity": "minor",
      "color": { "code": "blue", "red": 30, "green": 50, "blue": 205, "alpha": 1 },
      "effectiveTime": "2025-10-24T11:19+08:00",
      "onsetTime": "2025-10-24T11:19+08:00",
      "expireTime": "2025-10-25T11:19+08:00",
      "headline": "临桂区气象台更新大风蓝色预警信号",
      "description": "临桂区气象台24日11时19分继续发布大风蓝色预警信号...",
      "criteria": "24小时内可能受大风影响...",
      "instruction": "1.政府及有关部门按照职责做好防大风工作。\n2.关好门窗..."
    }
  ]
}
```

| 关键字段 | `alerts[].severity`(unknown/minor/moderate/severe/extreme)、`eventType.name/code`、`headline`、`description`、`instruction`、`expireTime` |

---

#### 12\. 天气预警（旧版，2026-10-01 停用）

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/warning/now` |
| **必选参数** | `location` |
| **可选参数** | `lang` |

**返回格式：** `warning[]` 数组，含 `id`/`title`/`typeName`/`severity`/`severityColor`/`text`/`startTime`/`endTime`/`status`(active/update)

---

### 六、天气指数

#### 13\. 天气指数预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/indices/{days}` |
| **必选参数** | `days` 路径（`1d`/`3d`）、`type`（指数ID，逗号分隔多值）、`location` |
| **可选参数** | `lang` |

**指数 type ID：** `1`运动 `2`洗车 `3`穿衣 `4`钓鱼 `5`紫外线 `6`旅游 `7`过敏 `8`舒适度 `9`感冒 `10`空气污染扩散 `11`空调开启 `12`太阳镜 `13`化妆 `14`晾晒 `15`交通 `16`防晒

**返回格式：**

```json
{
  "code": "200",
  "updateTime": "2021-12-16T18:35+08:00",
  "daily": [
    {
      "date": "2021-12-16",
      "type": "1",
      "name": "运动指数",
      "level": "3",
      "category": "较不宜",
      "text": "天气较好，但考虑天气寒冷，风力较强，推荐您进行室内运动..."
    }
  ]
}
```

| 关键字段 | `daily[].type/name`、`level`(等级)、`category`(级别名称)、`text`(描述) |

---

### 七、空气质量

#### 14\. 实时空气质量

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /airquality/v1/current/{lat}/{lng}` |
| **必选参数** | `latitude`、`longitude`（路径参数） |
| **可选参数** | —   |

**返回格式：**

```json
{
  "metadata": { "tag": "d75a323..." },
  "indexes": [
    {
      "code": "us-epa",
      "name": "AQI (US)",
      "aqi": 46,
      "aqiDisplay": "46",
      "level": "1",
      "category": "Good",
      "color": { "red": 0, "green": 228, "blue": 0, "alpha": 1 },
      "primaryPollutant": {
        "code": "pm2p5",
        "name": "PM 2.5",
        "fullName": "Fine particulate matter (<2.5µm)"
      },
      "health": {
        "effect": "No health effects.",
        "advice": {
          "generalPopulation": "Everyone can continue their outdoor activities normally.",
          "sensitivePopulation": "Everyone can continue their outdoor activities normally."
        }
      }
    },
    {
      "code": "qaqi",
      "name": "QAQI",
      "aqi": 0.9,
      "aqiDisplay": "0.9",
      "level": "1",
      "category": "Excellent"
    }
  ],
  "pollutants": [
    {
      "code": "pm2p5",
      "name": "PM 2.5",
      "fullName": "Fine particulate matter (<2.5µm)",
      "concentration": { "value": 11.0, "unit": "μg/m3" },
      "subIndexes": [
        { "code": "us-epa", "aqi": 46, "aqiDisplay": "46" },
        { "code": "qaqi", "aqi": 0.9, "aqiDisplay": "0.9" }
      ]
    },
    {
      "code": "pm10",
      "name": "PM 10",
      "concentration": { "value": 12.0, "unit": "μg/m3" }
    },
    {
      "code": "no2",
      "name": "NO2",
      "concentration": { "value": 6.77, "unit": "ppb" }
    },
    {
      "code": "o3",
      "name": "O3",
      "concentration": { "value": 0.02, "unit": "ppb" }
    },
    {
      "code": "co",
      "name": "CO",
      "concentration": { "value": 0.25, "unit": "ppm" }
    }
  ],
  "stations": [
    { "id": "P51762", "name": "North Holywood" }
  ]
}
```

| 关键字段 | `indexes[].code`(us-epa/qaqi)、`indexes[].aqi`、`indexes[].level/category/color`、`primaryPollutant`、`health.effect/advice`、`pollutants[].concentration`、`stations[]` |

---

#### 15\. 空气质量小时预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /airquality/v1/hourly/{lat}/{lng}` |
| **必选参数** | `latitude`、`longitude`（路径参数） |
| **可选参数** | `localTime`、`lang` |

**返回格式：** `hours[]` 数组，每项含 `forecastTime` + `indexes[]` + `pollutants[]`，结构与实时空气质量相似

---

#### 16\. 空气质量每日预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /airquality/v1/daily/{lat}/{lng}` |
| **必选参数** | `latitude`、`longitude`（路径参数） |
| **可选参数** | `localTime`、`lang` |

**返回格式：** `days[]` 数组，每项含 `forecastStartTime`/`forecastEndTime` + `indexes[]` + `pollutants[]`

---

#### 17\. 监测站数据

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /airquality/v1/stations/{locationId}` |
| **必选参数** | `locationId`（路径参数，如 `P58911`） |
| **可选参数** | —   |

**返回格式：**

```json
{
  "metadata": { "tag": "71f704f..." },
  "pollutants": [
    { "code": "pm2p5", "name": "PM 2.5", "concentration": { "value": 17.0, "unit": "μg/m3" } },
    { "code": "pm10", "name": "PM 10", "concentration": { "value": 47.0, "unit": "μg/m3" } },
    { "code": "no2", "name": "NO2", "concentration": { "value": 29.0, "unit": "μg/m3" } },
    { "code": "o3", "name": "O3", "concentration": { "value": 45.73, "unit": "μg/m3" } }
  ]
}
```

---

### 八、时光机（历史数据）

#### 18\. 天气时光机

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/historical/weather` |
| **必选参数** | `location`（仅 LocationID）、`date`（yyyyMMdd，近10天不含今日） |
| **可选参数** | `lang`、`unit`（`m`/`i`） |

**返回格式：**

```json
{
  "code": "200",
  "weatherDaily": {
    "date": "2020-07-25",
    "sunrise": "05:08",
    "sunset": "19:33",
    "moonrise": "09:54",
    "moonset": "22:40",
    "moonPhase": "峨眉月",
    "tempMax": "33",
    "tempMin": "23",
    "humidity": "52",
    "precip": "0.0",
    "pressure": "1000"
  },
  "weatherHourly": [
    {
      "time": "2020-07-25 00:00",
      "temp": "28",
      "icon": "100",
      "text": "晴",
      "precip": "0.0",
      "wind360": "246",
      "windDir": "西南风",
      "windScale": "2",
      "windSpeed": "8",
      "humidity": "49",
      "pressure": "1001"
    }
  ]
}
```

| 关键字段 | `weatherDaily{}`（当日汇总）、`weatherHourly[]`（逐小时历史） |

---

#### 19\. 空气质量时光机

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/historical/air` |
| **必选参数** | `location`（仅 LocationID）、`date`（yyyyMMdd，近10天不含今日） |
| **可选参数** | `lang` |

**返回格式：**

```json
{
  "code": "200",
  "airHourly": [
    {
      "pubTime": "2020-07-25 00:00",
      "aqi": "52",
      "level": "2",
      "category": "良",
      "primary": "PM10",
      "pm10": "54",
      "pm2p5": "22",
      "no2": "31",
      "so2": "2",
      "co": "0.5",
      "o3": "85"
    }
  ]
}
```

| 关键字段 | `airHourly[].pubTime`、`aqi`、`level`、`category`、`primary`（首要污染物）、`pm10`/`pm2p5`/`no2`/`so2`/`co`/`o3` |

---

### 九、热带气旋（台风）

#### 20\. 台风列表

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/tropical/storm-list` |
| **必选参数** | `basin`（NP/AL/EP/SP/NI/SI） |
| **可选参数** | `year` |

**返回格式：**

```json
{
  "code": "200",
  "storm": [
    {
      "id": "NP_2022",
      "name": "环高",
      "basin": "NP",
      "year": "2020",
      "isActive": "0"
    }
  ]
}
```

| 关键字段 | `storm[].id`（如 NP\_2022 用于后续查询）、`name`、`isActive`（1活跃/0停编） |

---

#### 21\. 台风实况和路径

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/tropical/storm-track` |
| **必选参数** | `stormid`（如 `NP2018`） |
| **可选参数** | —   |

**返回格式：**

```json
{
  "code": "200",
  "isActive": "1",
  "now": {
    "pubTime": "2024-05-30T05:00+08:00",
    "lat": "27.7",
    "lon": "134.5",
    "type": "STS",
    "pressure": "980",
    "windSpeed": "30",
    "moveSpeed": "21",
    "moveDir": "NE",
    "windRadius30": { "neRadius": "120", "seRadius": "150", "swRadius": "120", "nwRadius": "100" },
    "windRadius50": { "neRadius": "60", "seRadius": "60", "swRadius": "60", "nwRadius": "50" }
  },
  "track": [
    {
      "time": "2024-05-29T17:00+08:00",
      "lat": "26.1",
      "lon": "132.5",
      "type": "TY",
      "pressure": "970",
      "windSpeed": "35",
      "moveSpeed": "28",
      "moveDir": "NE",
      "windRadius30": { ... },
      "windRadius50": { ... },
      "windRadius64": { ... }
    }
  ]
}
```

| 关键字段 | `isActive`、`now{}`（当前实况）、`track[]`（历史轨迹点）、`type`(TD/TS/STS/TY)、`windRadius30/50/64`（风圈半径） |

---

#### 22\. 台风预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/tropical/storm-forecast` |
| **必选参数** | `stormid`（如 `NP2018`） |
| **可选参数** | —   |

**返回格式：**

```json
{
  "code": "200",
  "forecast": [
    {
      "fxTime": "2021-07-27T20:00+08:00",
      "lat": "31.7",
      "lon": "118.4",
      "type": "TS",
      "pressure": "990",
      "windSpeed": "18",
      "moveSpeed": "",
      "moveDir": "",
      "move360": ""
    }
  ]
}
```

| 关键字段 | `forecast[].fxTime`、`lat/lon`、`type`、`pressure`、`windSpeed`、`moveSpeed/Dir` |

---

### 十、海洋数据

#### 23\. 潮汐

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/ocean/tide` |
| **必选参数** | `location`（潮汐站 ID，如 `P66981`）、`date`（yyyyMMdd） |
| **可选参数** | —   |

**返回格式：**

```json
{
  "code": "200",
  "tideTable": [
    { "fxTime": "2021-02-06T03:48+08:00", "height": "2.17", "type": "H" },
    { "fxTime": "2021-02-06T10:12+08:00", "height": "0.21", "type": "L" }
  ],
  "tideHourly": [
    { "fxTime": "2021-02-06T00:00+08:00", "height": "1.02" }
  ]
}
```

| 关键字段 | `tideTable[]`（满潮/干潮时刻表，`type`: H=满潮/L=干潮）、`tideHourly[]`（逐小时潮高） |

---

### 十一、太阳辐射

#### 24\. 太阳辐射预报

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /solarradiation/v1/forecast/{lat}/{lng}` |
| **必选参数** | `latitude`、`longitude`（路径参数） |
| **可选参数** | `hours`（1-60，默认24）、`interval`（15/30/60分钟）、`tilt`（0-90°倾角）、`azimuth`（0-359°方位角）、`extra`（`weather`/`poa`）、`localTime` |

**返回格式：**

```json
{
  "metadata": { "tag": "c4ca4238..." },
  "forecasts": [
    {
      "forecastTime": "2023-10-15T11:30Z",
      "solarAngle": { "azimuth": 184, "elevation": 40 },
      "dni": { "value": 25.16, "unit": "W/m²" },
      "dhi": { "value": 136.29, "unit": "W/m²" },
      "ghi": { "value": 152.57, "unit": "W/m²" },
      "weather": {
        "temperature": { "value": 18.6, "unit": "°C" },
        "windSpeed": { "value": 2.78, "unit": "m/s" },
        "humidity": 76
      },
      "poa": {
        "global": { "value": 134.39, "unit": "W/m²" },
        "direct": { "value": 9.35, "unit": "W/m²" },
        "diffuse": { "value": 125.04, "unit": "W/m²" },
        "reflected": { "value": 1.52, "unit": "W/m²" }
      }
    }
  ]
}
```

| 关键字段 | `dni`（直接法向辐照度）、`dhi`（散射水平辐照度）、`ghi`（总水平辐照度）、`solarAngle`（太阳角度）、`poa`（阵列平面辐照度，需传 `tilt`+`azimuth`）、`weather`（附带气象） |

---

### 十二、天文

#### 25\. 日出日落

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/astronomy/sun` |
| **必选参数** | `location`、`date`（yyyyMMdd，未来60天） |
| **可选参数** | —   |

**返回格式：**

```json
{
  "code": "200",
  "updateTime": "2021-02-17T11:00+08:00",
  "sunrise": "2021-02-20T06:58+08:00",
  "sunset": "2021-02-20T17:57+08:00"
}
```

| 关键字段 | `sunrise`、`sunset`（高纬度可能为空） |

---

#### 26\. 月升月落和月相

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/astronomy/moon` |
| **必选参数** | `location`、`date`（yyyyMMdd，未来60天） |
| **可选参数** | `lang` |

**返回格式：**

```json
{
  "code": "200",
  "updateTime": "2021-11-15T17:00+08:00",
  "moonrise": "2021-11-20T17:25+08:00",
  "moonset": "2021-11-21T07:42+08:00",
  "moonPhase": [
    {
      "fxTime": "2021-11-20T00:00+08:00",
      "value": "0.51",
      "name": "亏凸月",
      "illumination": "100",
      "icon": "805"
    }
  ]
}
```

| 关键字段 | `moonrise/moonset`（可能为空）、`moonPhase[]`（逐小时月相，`name`/`value`/`illumination`/`icon`） |

---

#### 27\. 太阳高度角

| 项目  | 内容  |
| --- | --- |
| **路径** | `GET /v7/astronomy/solar-elevation-angle` |
| **必选参数** | `location`、`date`（yyyyMMdd）、`time`（HHmm）、`tz`（±HHMM）、`alt`（海拔高度，米） |
| **可选参数** | —   |

**返回格式：**

```json
{
  "code": "200",
  "solarElevationAngle": "42.88",
  "solarAzimuthAngle": "185.92",
  "solarHour": "1217",
  "hourAngle": "-4.41"
}
```

| 关键字段 | `solarElevationAngle`（太阳高度角）、`solarAzimuthAngle`（方位角，正北顺时针）、`hourAngle`（时角） |

---

### 通用字段说明

| 通用字段 | 含义  |
| --- | --- |
| `code` | 状态码，"200" 成功 |
| `updateTime` | API 最近更新时间 |
| `fxLink` | 数据对应的响应式网页链接 |
| `refer.sources` | 数据来源 |
| `refer.license` | 数据许可 |

### 认证方式

所有请求在 HTTP Header 中添加：`Authorization: Bearer <your_jwt_token>`（注意你当前代码用的是 `key` 查询参数方式，如果是 JWT 模式请替换为 Header 方式）