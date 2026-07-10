# TODO

### 概览


>基于Qt网络模块调用公开天气API（如和风天气），实现城市天气查询、7天预报、空气质量指数展示。

>前端采用QML设计动态天气图标（晴/雨/雪），支持主题切换与语音播报。

>数据缓存使用SQLite，减少重复请求。

>集成地图插件显示城市位置（拓展功能）。

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
2. 设计前端界面
     - 和风天气图标项目(https://icons.qweather.com/)
3. 创建缓存数据库


#### conclusion

1. **weather API**
    - 坑: qt6 中所有信号需要首字母小写
     -  设计要点
    
        | 层次  | 说明  |
        | --- | --- |
        | **请求函数** | 每个 API 一个 `Q_INVOKABLE`，组装 URL + 参数，调 `sendRequest()` |
        | `sendRequest()` | 统一打 `QNetworkRequest::User` 属性标记，消除重复代码 |
        | `onReplyFinished()` | 读标记 → switch 路由，新增 API 只加一行 case |
        | **Handler** | 一个函数 3~5 行，只做 JSON 解析 + emit 信号 |
        | **信号** | Object / Array 类型精确匹配 API 返回结构，QML 端不用再解析 JSON |
        



 