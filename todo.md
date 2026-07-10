# TODO

### 概览


>基于Qt网络模块调用公开天气API（如和风天气），实现城市天气查询、7天预报、空气质量指数展示。

>前端采用QML设计动态天气图标（晴/雨/雪），支持主题切换与语音播报。

>数据缓存使用SQLite，减少重复请求。

>集成地图插件显示城市位置（拓展功能）。

### 细节
1. 界面设计: 
    - 动态天气背景: 根据焦点控件显示的天气信息不同,整个背景优雅的动态变化成对应的天气:*如初始状态是晴天,选中了天津(阴天),云从边界外移动进来遮住太阳,整个界面变成阴天的色调* 可能的[实现路径](indicationsForDynamic_background.md)
    - 基本界面设计: [效果图](效果图2.svg) 
        - 信息显示控件: 半透明,小圆角矩形,确保文字清晰可见.进阶要求:色调根据动态天气背景变化
    - 图标: 采用[和风天气图标项目](https://icons.qweather.com/)
    - 白天/黑夜模式
2. 行为: 
    - 当用户未选择城市时,调取数据库历史城市若历史查看城市不足填满 dashboard , 调用 citytop 获取热门城市显示在 dashboard 信息卡片中.
    
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
     - [和风天气图标项目](https://icons.qweather.com/)
3. 创建缓存数据库


#### conclusion

1. **weather API**
    - 坑: qt6 中所有与QML通信的信号需要首字母小写
     -  设计要点
    
        | 层次  | 说明  |
        | --- | --- |
        | **请求函数** | 每个 API 一个 `Q_INVOKABLE`，组装 URL + 参数，调 `sendRequest()` |
        | `sendRequest()` | 统一打 `QNetworkRequest::User` 属性标记，消除重复代码 |
        | `onReplyFinished()` | 读标记 → switch 路由，新增 API 只加一行 case |
        | **Handler** | 一个函数 3~5 行，只做 JSON 解析 + emit 信号 |
        | **信号** | Object / Array 类型精确匹配 API 返回结构，QML 端不用再解析 JSON |
    - 回复处理时加入location属性便于区分
        - onReplyFinished — 从请求 URL 提取 location 参数，传给所有 handler
        - Object 类型的 handler — 注入 obj["_location"] = loc 后 emit
        - Array 类型 — 不改信号签名, location 传入 signal 中
2. **界面设计** 
    - 


 