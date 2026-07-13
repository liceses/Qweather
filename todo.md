# TODO

### 概览


>基于Qt网络模块调用公开天气API（如和风天气），实现城市天气查询、7天预报、空气质量指数展示。

>前端采用QML设计动态天气图标（晴/雨/雪），支持主题切换与语音播报。

>数据缓存使用SQLite，减少重复请求。

>集成地图插件显示城市位置（拓展功能）。

### 细节
1. 界面设计: 
    - 动态天气背景: 
        * 根据焦点控件显示的天气信息不同,整个背景优雅的动态变化成对应的天气:可能的[实现路径](indicationsForDynamic_background.md)
        >如 初始状态是晴天,选中了天津(阴天),云从边界外移动进来遮住太阳,整个界面变成阴天的色调
        * 动态背景可以根据鼠标在页面中的对应微微偏移,晃动
    - 基本界面设计: [效果图](效果图2.svg) 
        * 信息显示控件: 半透明,小圆角矩形,确保文字清晰可见.进阶要求:色调根据动态天气背景变化
        * 响应式布局
    - 图标: 采用[和风天气图标项目](https://icons.qweather.com/)
    - 白天/黑夜模式
    - *低优先级*添加小宠物,闲时趴在边缘,点击时展开
2. 行为: 
    - 接入SQLite 数据库作为缓存 设置合理的有效时间
    - 双击dashboard中某一个具体的城市卡片时,跳转到城市详情页面,显示这个城市可以获取到的所有信息,用卡片的形式堆叠,如果信息过多,可以滚动页面,上方有城市名大字
    - 侧边栏 有: 
        - =======信息=======
        - dashboard ,
        - 具体城市(双击城市卡片跳转,也可以进入页面手动设置城市,默认为dashboard中第一个城市),信息显示该城市的[所有可获取信息](和风天气API.md)
        - 空气质量(和dashboard一样的布局,城市数量限制为固定值,默认为4,信息卡片2*2布局,显示信息从实时温度改为空气质量),
        - 天气预报(和dashboard一样,城市数量限制为固定值,默认为4,信息卡片2*2布局,显示信息改为天气预报(可以选择预报范围 24h/72h/168h , 3d/7d/10d/15d/30d ))
        - 阳光天文(和dashboard一样,城市数量限制为固定值,默认为4,信息卡片2*2布局,显示信息改为[太阳辐射+天文](和风天气API.md))
        - =======城市=======
        - 焦点城市
        - ...
        - =======
        - 收藏: 显示用户收藏的城市,双击城市卡片可以跳转至该城市的详情页面
        - 设置: 包揽所有设置项
    - 当用户未选择城市时,调取数据库历史城市若历史查看城市不足填满 dashboard , 调用 citytop 获取热门城市显示在 dashboard 信息卡片中.
    - *低优先级*,宠物会说一些天气相关的话,有语音播报的功能,进阶功能接入语言大模型api 提供相关对话功能    


# DATE

### 2026.7.09
1. 完成了和风天气api基础调用
    
    - 申请了和风天气的**apikey** , 了解到 还有 **JWT** 身份验证方式,列为代办
    - 了解**QNetWorkAccessManager** , **QNetWorkReply** 等网络通信库
    - 了解**Qt Json**相关解析库 : 
        - **QJsonObject** : 从 json 格式文档 提供json对象的交互
        - **QJsonDocument** : 将 string ( QByteArray )解析为 json 格式文档
        - **QJsonArray** : 从 json 格式文档 提供json数据的交互
2. 了解了QML语言基础,为界面的构建打下基础
3. git 仓库连接 华为 codearts 远程仓库成功

### 2026.7.10

#### TODO:
1. 规范weatherAPI 
    * 完成
2. 设计前端界面
     - [和风天气图标项目](https://icons.qweather.com/)
     * 进行中 7.10 20:00
3. 创建缓存数据库
    * 未开始 7.10 20:00


#### conclusion

1. **weather API**
    - **坑**: qt6 中所有与QML通信的信号需要首字母小写
     - **设计要点**
    
        | 层次  | 说明  |
        | --- | --- |
        | **请求函数** | 每个 API 一个 `Q_INVOKABLE`，组装 URL + 参数，调 `sendRequest()` |
        | `sendRequest()` | 统一打 `QNetworkRequest::User` 属性标记，消除重复代码 |
        | `onReplyFinished()` | 读标记 → switch 路由，新增 API 只加一行 case |
        | **Handler** | 一个函数 3~5 行，只做 JSON 解析 + emit 信号 |
        | **信号** | Object / Array 类型精确匹配 API 返回结构，QML 端不用再解析 JSON |
    - 回复处理时加入**location**属性便于区分
        - onReplyFinished — 从请求 URL 提取 location 参数，传给所有 handler
        - Object 类型的 handler — 注入 obj["_location"] = loc 后 emit
        - Array 类型 — 不改信号签名, location 传入 signal 中


#### 问题反馈:
1. 焦点城市名 是一串数字,疑似将locationId当城市名字了.
2. 城市卡片行  添加按钮 点击无作用
3. searchBar 疑似样式未生效, 过于简单,不符合整体风格
4. 所有组件都没有鼠标 hangover 的显示
5. 左侧栏应该是可以展开的,展开至一定宽度
6. 点击左侧栏切换界面时应该有过渡动画
7. 点击左侧栏navbut时,不会高亮对应button
8. 未实现动态天气图标
9. 未实现响应式布局, 一些组件如citycard等组件的大小是固定的像素大小
10. 未实现全局

//已过期


### 2026.7.13

#### 问题反馈:
1. 仪表盘
    - 焦点城市 infochip 所有数据显示 undefined , 且温度显示 --
    - citycard 还是没有hover ,其双击跳转不到详情界面,单击也不能切换焦点城市了
    - searchBar 还是没有样式
2. API调用问题
    - 所有需要新数据的地方都没有显示,检查是否是判断缓存或获取的函数逻辑有误
3. 侧边栏展开没有动画过渡



#### 11:17问题反馈:
1. 仪表盘 infochip 所有数据显示 -- 还是没数据
    - 单击 卡片任然不能切换焦点城市
    - searchBar 不能用了
2. 空气质量 天气预报 阳光天文还是没数据 

#### TODO
1. 焦点城市行为总览:
    - 用户第一次打开应用:无历史城市,无收藏城市,dashboard城市卡片自动获取topcity显示前几个(数量用户规定默认4个),焦点城市聚焦为第一个城市卡片的城市
    - 用户点击某一个城市卡片,若与当前焦点城市不同,则焦点城市重新聚焦于用户点击的城市
    - 用户在dashboard界面通过searchBar搜索并选择了某个城市(城市x) 焦点城市重新聚焦于x ,并且对应的城市卡片的城市也被替换为x
    - 用户在收藏页面单击城市卡片x,焦点聚焦到x
    - 每当焦点城市改变时,侧边栏城市详情城市也自动改变
    - 优先级:固定>收藏>历史 当有用户历史城市时,选用最新查看的城市;当有用户收藏城市时,选用第一个收藏城市;当用户固定了某一城市时侧边城市分区详情城市被固定为这个城市,以后再固定城市往后追加
2. 收藏行为
    - 城市详情页面有星号图标,点击收藏,添加到收藏页面
    - 在收藏页面,每个城市卡片有固定按钮,点击固定到侧边栏城市分区
    - 收藏需要持久化


### 2026.7.13 空气质量功能实现

#### 架构
采用 ForecastStore → ForecastPage → ForecastCard 同款 C++ 数据层模式：

```
Main.qml cityList (含 lat/lon)
  → AirQualityStore.setCities()
    → 逐个 airCurrent(lat, lng, cityId)
      → airCurrentReady(cityId, JSON)
        → AirQualityStore.onAirCurrentReady()
          → 解析 indexes/us-epa、pollutants、color
          → 写入 airData[cityId] = {aqi, category, color, pollutants...}
          → emit airDataChanged()
            → AirQualityCard 绑定刷新
```

#### 文件变更

| 操作 | 文件 | 说明 |
|------|------|------|
| 修改 | `weatherApi.h` | airCurrent/airHourly/airDaily 增加 cityId 参数；信号改为 `(QString cityId, QJsonObject)` |
| 修改 | `weatherApi.cpp` | airCurrent 增加缓存读取；URL 注入 `_loc` 查询参数追踪城市；handler 改用新信号签名；onReplyFinished 兼容 `_loc` 参数提取 |
| 修改 | `Main.qml` | 城市数据增加 lat/lon 字段；空气占位页替换为 AirQualityPage；cityList 变更同步到 AirQualityStore |
| 修改 | `main.cpp` | 注册 AirQualityStore 上下文属性 |
| 修改 | `CMakeLists.txt` | 添加 AirQualityStore.h/.cpp、AirQualityPage.qml、AirQualityCard.qml |
| 新增 | `AirQualityStore.h` | C++ 数据层 — cities/airData Q_PROPERTY，解析 AQI JSON |
| 新增 | `AirQualityStore.cpp` | refreshAll() 调 airCurrent；onAirCurrentReady() 解析 indexes/pollutants/color |
| 新增 | `AirQualityPage.qml` | 2×2 Grid 布局，绑定 airQualityStore |
| 新增 | `AirQualityCard.qml` | AQI 大数字 + 彩色圆点 + 类别标签 + 首要污染物 + 污染物浓度网格 |

#### 已知 bug 修复
- `AirQualityCard.qml:80` — `card.airData.pollutants && length > 0` 在 pollutants 为 undefined 时返回 undefined 无法赋值 bool，改为 `!!card.airData.pollutants && ...`


### 2026.7.13 天气预报功能实现 (QtCharts)

#### 架构

采用 C++ ForecastStore 数据层 + QML 纯渲染模式：

```
Main.qml cityList
  → ForecastStore.setCities()
    → 逐个 weatherDaily(range, cityId) / weatherHourly(range, cityId)
      → weatherDailyReady(loc, JSON) / weatherHourlyReady(loc, JSON)
        → ForecastStore.onWeatherDailyReady() / onWeatherHourlyReady()
          → 解析 daily[]/hourly[] → {x: msec, y: temp} 坐标数组
          → 写入 chartData[cityId + "_daily"/"_hourly"] = points
          → chartData[cityId + "_info"] = {icon, text, iconDay, textDay}
          → emit chartDataChanged()
            → ForecastCard.points 绑定重求值
              → onPointsChanged → updateChart() 渲染
```

#### 范围选择器

8 个选项分两组：
- 逐小时: `24h`, `72h`, `168h` → `weatherApi.weatherHourly()`
- 逐日: `3d`, `7d`, `10d`, `15d`, `30d` → `weatherApi.weatherDaily()`

后缀 `h`/`d` 判定模式，切换时 ForecastStore.setRange() → refreshAll()。

#### 文件变更

| 操作 | 文件 | 说明 |
|------|------|------|
| 新增 | `ForecastStore.h` | C++ 数据层 — cities/range/mode/chartData Q_PROPERTY，JSON→图表坐标预处理 |
| 新增 | `ForecastStore.cpp` | setWeatherApi() 连接 weatherDailyReady/hourlyReady 信号；refreshAll() 遍历城市调 API；handler 解析 JSON |
| 新增 | `ForecastPage.qml` | 范围选择器 + 2×2 Grid 布局，纯 UI |
| 新增 | `ForecastCard.qml` | 城市卡片：WeatherIcon + 城市名 + 天气描述 + ChartView(预声明 3 series) |
| 修改 | `Main.qml` | cityList 变更同步到 forecastStore.cities；占位页替换为 ForecastPage |
| 修改 | `main.cpp` | QGuiApplication→QApplication；注册 forecastStore 为 context property |
| 修改 | `CMakeLists.txt` | +Widgets, +Charts, +ForecastStore.h/.cpp |

#### 图表渲染方案（经多次迭代）

最终方案：**预声明 series + ValueAxis(序号索引) + clear→append**

- ChartView 预声明 SplineSeries(温度) + LineSeries×2(最高温/最低温)，按模式切换 visible
- X 轴用 ValueAxis，X 值用序列索引 (0,1,2...)，依次表示第 N 小时/天
- Y 轴用 ValueAxis，updateChart() 中遍历 points 计算 yMin/yMax + 10% 边距，设轴→clear→append

#### 踩坑记录

| 问题 | 现象 | 根因 | 解决方案 |
|------|------|------|---------|
| QGuiApplication 崩溃 | SIGSEGV | QtCharts 内部用 QGraphicsTextItem→QWidgetTextControl，依赖 QtWidgets | QGuiApplication → QApplication |
| DateTimeAxis 不渲染 | 折线不显示 | Qt 6 Charts QML 中 DateTimeAxis + 预声明 series 不兼容 | 改用 ValueAxis + 序号索引 |
| `clear()` 后轴不自动缩放 | 折线压在底部 | Qt Charts: clear() 后 axis 范围保持不变，不自动重新缩放 | 先算范围→setRange→clear→append |
| `removeAllSeries()` + `createSeries()` 产生 NaN | Ignored NaN 警告泛滥 | 清理/重建 series 导致轴进入无效状态 | 改为预声明 series + clear() + append() |
| `labelFormat: "%.0f°"` 乱码 | Y 轴显示 `?C` | Windows 字体不支持 `°` 字符 | 去掉特殊字符 |
| QML `property var` 绑定不更新 | 卡片无数据 | JS 对象原地修改引用不变，QML Changed 信号不触发 | C++ 端每次创建新 QVariantMap |
| C++ `QDateTime` 时区 | X 轴显示大数字 | `fromString("yyyy-MM-dd")` 默认 LocalTime，`toMSecsSinceEpoch()` 正确转为 UTC 毫秒 | 无需修复（转为序号索引后不再使用） |

#### 设计教训

1. **C++ 数据预处理 > QML JS**：JSON 解析、日期转换、类型转换移到 C++，消除 ReferenceError/类型错误/信号丢失一整类 bug
2. **Qt Charts 必须 QApplication**：内部依赖 QWidgetTextControl(Graphics View)
3. **预声明 series 优于 createSeries**：ChartView + 预声明 children 比动态创建稳定
4. **QML 属性绑定 ≠ JS 深比较**：`property var` 依赖引用判等，深层修改不触发 Changed 信号
5. **先设轴范围后清数据**：clear() 后 axis 状态失效，提前设 range 避免 NaN 间隙



### 2026.7.13 阳光天文功能实现

#### 架构

采用 AirQualityStore 同款 C++ 数据层 + QML 纯渲染模式，差异在于每城需 3 路 API 异步合并：

```
Main.qml cityList (含 lat/lon)
  → SolarAstronomyStore.setCities()
    → 每城 3 路 API:
      solarRadiation(lat, lng, cityId)     → forecasts[0] → ghi/dni/dhi/solarAngle
      astronomySun(locId, date, cityId)    → sunrise/sunset
      astronomyMoon(locId, date, cityId)   → moonPhase[0] → name/icon/illumination
    → m_solarRaw[cityId] 中间累积 3 路结果
      → mergeAndEmit() 合并 → m_solarData[cityId] 写入 → emit solarDataChanged()
        → SolarAstronomyCard 绑定刷新
```

#### 文件变更

| 操作 | 文件 | 说明 |
|------|------|------|
| 修改 | `weatherApi.h` | solarRadiation/astronomySun/astronomyMoon 增加 cityId 参数；3 个信号改为 `(QString cityId, QJsonObject)` |
| 修改 | `weatherApi.cpp` | 3 个 API 注入 `_loc` 查询参数追踪城市；handler 改用新信号签名；天文缓存键含日期；`onReplyFinished` 路由提取改为 `_loc` 优先 |
| 新增 | `SolarAstronomyStore.h` | C++ 数据层 — cities/solarData Q_PROPERTY，3 个 handler slot，mergeAndEmit() |
| 新增 | `SolarAstronomyStore.cpp` | setWeatherApi() 连接 3 个信号；refreshAll() 对前 4 城各调 3 路 API；m_solarRaw 中间累积 → mergeAndEmit 合并写入 |
| 新增 | `SolarAstronomyCard.qml` | GHI 大数字 + DNI/DHI 副行 + 日出日落时间行 + 月相名称/亮度 + 无数据兜底 |
| 新增 | `SolarAstronomyPage.qml` | 2×2 Grid 布局，绑定 solarAstronomyStore |
| 修改 | `Main.qml` | 占位页替换为 SolarAstronomyPage；cityList 时同步到 solarAstronomyStore.cities |
| 修改 | `main.cpp` | 实例化 + 注册 solarAstronomyStore 上下文属性 |
| 修改 | `CMakeLists.txt` | 添加 4 个新文件 |

#### 踩坑记录

| 问题 | 现象 | 根因 | 解决方案 |
|------|------|------|---------|
| 天文学 API 无响应 | 卡片只显示 GHI/DNI/DHI，无日出日落/月相 | `onReplyFinished` 中 `q.queryItemValue("location")` 对天文学 API 返回 "lat,lng"（非空），导致 `_loc`（cityId）被跳过，信号路由到错误的 key | 改为 `_loc` 优先提取：`q.queryItemValue("_loc")` 优先，`location` 回退 |
| astronomySun/astronomyMoon 请求不返回 | solarReady 正常但 sunReady/moonReady 日志永远不出现 | Store 传 `"lat,lng"` 格式给 `/v7/astronomy/*` 端点，devapi 代理不支持此格式 | 改用 LocationID（cityId），与 ForecastStore 调用天气 API 的方式一致 |

#### 设计教训

1. **`_loc` 优先于 `location` 提取路由键**：当 API 同时具有 `location`（业务参数）和 `_loc`（追踪参数）时，追踪参数应优先，否则 cityId 丢失导致数据路由失败
2. **新增端点优先复用已验证的参数格式**：ForecastStore 用 LocationID 调用所有天气 API 始终正常 — 新端点不应假设文档中所有格式在代理环境下都能工作
3. **多路异步 API 用中间累积 → 统一 emit 模式**：3 路 API 返回时序不确定，`m_solarRaw` 中间缓冲 + `mergeAndEmit` 合并写入，确保 QML 侧只需绑定一个属性即可拿到所有字段


### 2026.7.13 城市详情页实现

#### 架构

采用 CityDetailStore（C++ 数据层）→ CityDetailPage（QML 纯渲染）模式：

```
Main.qml focusId 变更
  → cityDetailStore.setCity(id, name, lat, lon)
    → 并行调用 10 个 API：
      weatherNow / weatherDaily / weatherHourly
      / airCurrent / indices / warningNow
      / astronomySun / astronomyMoon
      / solarRadiation / minutelyPrecip
    → 各 handler 解析 JSON → 写入 QVariantMap(m_detail) → emit detailChanged()
      → CityDetailPage 9 张卡片按数据到达依次出现
```

#### 文件变更

| 操作 | 文件 | 说明 |
|------|------|------|
| 新增 | `CityDetailStore.h/.cpp` | C++ 数据层 — 汇聚单城市全部 API 数据为一个 QVariantMap |
| 新增 | `CityDetailPage.qml` | Flickable 滚动 + 9 张卡片堆叠 |
| 修改 | `CMakeLists.txt` | 添加 CityDetailStore 源文件、CityDetailPage.qml |
| 修改 | `main.cpp` | 实例化 CityDetailStore 并注册为 context property |
| 修改 | `Main.qml` | 页面 5 占位替换为 CityDetailPage；onFocusIdChanged 调用 setCity() |

#### 踩坑记录

| 问题 | 现象 | 根因 | 解决方案 |
|------|------|------|---------|
| Grid polish loop | 控制台刷屏 `Grid called polish() inside updatePolish()` | Grid 子项 `width: parent.width / N` — Grid 算子项宽度依赖子项尺寸，子项尺寸又依赖 Grid 宽度，形成循环依赖 | 子项宽度引用卡片级 ID（如 `nowCard.width`），其宽度由锚定固定，不依赖子项 |
| QML Layout 内使用 anchors | `Detected anchors on an item that is managed by a layout` | ColumnLayout/RowLayout 内的子项使用 `anchors.horizontalCenter: parent.horizontalCenter` | 替换为 `Layout.alignment: Qt.AlignHCenter` |
| `visible` 绑定返回 undefined 导致卡片错误显示 | 所有卡片启动时全显示 + TypeError 刷屏 | `visible: detail.now && detail.now.temp` 中 `detail.now` 为 undefined 时整个表达式返回 undefined，赋值给 bool 失败，Qt 保留默认值 true | 所有 guard 使用 `!!` 强制布尔化：`visible: !!detail.now && !!detail.now.temp` |
| `visible: false` 卡片内部绑定仍求值 TypeError | 卡片已隐藏但仍报 `Cannot read property 'xxx' of undefined` | QML 始终评估所有已实例化组件的绑定表达式，深层属性访问 `detail.now.temp` 需要中间对象 `detail.now` 存在，否则 TypeError | C++ 端预初始化所有嵌套 map/list 为空对象：`m_detail["now"] = QVariantMap()` 等，在构造函数和 setCity() 两处执行 |

#### 设计教训

1. **Grid 子项禁引用 parent.width**：绑定到卡片级 ID 规避 polish loop
2. **`undefined && x` 返回 `undefined` 非 `false`**：QML 中所有 visible guard 表达式必须用 `!!` 强制返回布尔值
3. **`visible: false` 不阻止绑定求值**：深层属性访问需要中间对象存在 — C++ 端预初始化空 map/list 可消解整类 TypeError
4. **预初始化要在最早位置执行**：构造函数和 setCity() 都需预初始化，因为 QML 绑定在首个 onFocusIdChanged 之前就已开始求值
4. **日志分层命名**：`[SolarAstronomy]` 前缀 + solarReady/sunReady/moonReady 子标签，一眼看出哪路数据到达、哪路缺失