#ifndef WEATHERAPI_H
#define WEATHERAPI_H
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class WeatherCache;

// ApiRequestType — Request type enum for unified routing via QNetworkRequest::User attribute
// 请求类型枚举，用于 QNetworkRequest::User 属性标记，实现统一路由分发
enum class ApiRequestType {
    CityLookup,         // 城市搜索
    CityTop,            // 热门城市
    WeatherNow,         // 实时天气
    WeatherDaily,       // 逐日预报
    WeatherHourly,      // 逐小时预报
    GridWeatherNow,     // 格点实时天气
    GridWeatherDaily,   // 格点逐日预报
    GridWeatherHourly,  // 格点逐小时预报
    MinutelyPrecip,     // 分钟级降水
    WarningNow,         // 实时预警
    Indices,            // 天气指数
    AirCurrent,         // 实时空气质量
    AirHourly,          // 空气质量小时预报
    AirDaily,           // 空气质量每日预报
    HistoricalWeather,  // 天气时光机
    HistoricalAir,      // 空气质量时光机
    StormList,          // 台风列表
    StormTrack,         // 台风实况和路径
    StormForecast,      // 台风预报
    OceanTide,          // 潮汐
    SolarRadiation,     // 太阳辐射
    AstronomySun,       // 日出日落
    AstronomyMoon,      // 月升月落
    SolarElevationAngle // 太阳高度角
};

// WeatherAPI — Network facade for QWeather API with caching support
// 和风天气 API 网络封装层，支持缓存注入，所有接口可直接从 QML 调用
class WeatherAPI :public QObject{
    Q_OBJECT
public:
    explicit WeatherAPI(QObject* parent = nullptr);

    // setCache — Inject cache layer; nullptr disables caching / 注入缓存层，设为 nullptr 则禁用缓存
    void setCache(WeatherCache *cache) { m_cache = cache; }

    // setApiConfig — Set API key and host at runtime / 运行时设置 API 密钥和地址
    Q_INVOKABLE void setApiConfig(const QString &key, const QString &host = "");

    // requestCounts — Get per-endpoint request counts / 获取各端点请求计数
    Q_INVOKABLE QVariantMap requestCounts() const;

    // ===== QML-callable API methods / 以下函数均可从 QML 直接调用 =====

    // —— GeoAPI — Geographic info / 地理信息 ——
    Q_INVOKABLE void searchCity(const QString &name);            // City name search / 城市搜索
    Q_INVOKABLE void topCity(const QString &range = "cn", int number = 10);  // Hot cities / 热门城市

    // —— Weather forecast / 天气预报 ——
    Q_INVOKABLE void weatherNow(const QString &loc);            // Real-time weather / 实时天气
    Q_INVOKABLE void weatherDaily(const QString &days, const QString &loc);  // Daily forecast / 逐日预报
    Q_INVOKABLE void weatherHourly(const QString &hours, const QString &loc); // Hourly forecast / 逐小时预报

    // —— Grid weather / 格点天气 ——
    Q_INVOKABLE void gridWeatherNow(const QString &loc);
    Q_INVOKABLE void gridWeatherDaily(const QString &days, const QString &loc);
    Q_INVOKABLE void gridWeatherHourly(const QString &hours, const QString &loc);

    // —— Precipitation / 分钟级降水 ——
    Q_INVOKABLE void minutelyPrecip(const QString &loc);

    // —— Warnings / 实时预警 (v1) ——
    Q_INVOKABLE void warningNow(const QString &lat, const QString &lng);

    // —— Weather indices / 天气指数 ——
    Q_INVOKABLE void indices(const QString &days, const QString &type, const QString &loc);

    // —— Air quality / 空气质量 ——
    Q_INVOKABLE void airCurrent(const QString &lat, const QString &lng, const QString &cityId = "");
    Q_INVOKABLE void airHourly(const QString &lat, const QString &lng, const QString &cityId = "");
    Q_INVOKABLE void airDaily(const QString &lat, const QString &lng, const QString &cityId = "");

    // —— Historical (time machine) / 时光机 ——
    Q_INVOKABLE void historicalWeather(const QString &loc, const QString &date);
    Q_INVOKABLE void historicalAir(const QString &loc, const QString &date);

    // —— Typhoon / 台风 ——
    Q_INVOKABLE void stormList(const QString &basin, const QString &year = "");
    Q_INVOKABLE void stormTrack(const QString &sid);
    Q_INVOKABLE void stormForecast(const QString &sid);

    // —— Ocean / 海洋 ——
    Q_INVOKABLE void oceanTide(const QString &loc, const QString &date);

    // —— Solar radiation / 太阳辐射 ——
    Q_INVOKABLE void solarRadiation(const QString &lat, const QString &lng,
                                    const QString &cityId = "",
                                    int hours = 24, int interval = 60);

    // —— Astronomy / 天文 ——
    Q_INVOKABLE void astronomySun(const QString &loc, const QString &date,
                                  const QString &cityId = "");  // Sunrise/sunset / 日出日落
    Q_INVOKABLE void astronomyMoon(const QString &loc, const QString &date,
                                   const QString &cityId = ""); // Moonrise/moonset / 月升月落
    Q_INVOKABLE void solarElevAngle(const QString &loc, const QString &date,
                                    const QString &time, const QString &tz, const QString &alt); // Solar elevation / 太阳高度角


signals:
    // Signals emitted after API query completes; consumed by QML / 查询完成后发出的信号，QML 端自动接收
    void ErrorOccured(const QString &err);  // Network / API error / 网络或 API 错误

    // —— GeoAPI / 地理信息 ——
    void cityLookupReady(const QJsonArray &locations);
    void cityTopReady(const QJsonArray &cities);

    // —— Weather forecast / 天气预报 ——
    void weatherNowReady(const QJsonObject &now);
    void weatherDailyReady(const QString &loc, const QJsonArray &daily);
    void weatherHourlyReady(const QString &loc, const QJsonArray &hourly);

    // —— Grid weather / 格点天气 ——
    void gridWeatherNowReady(const QJsonObject &now);
    void gridWeatherDailyReady(const QString &loc, const QJsonArray &daily);
    void gridWeatherHourlyReady(const QString &loc, const QJsonArray &hourly);

    // —— Precipitation / 分钟级降水 ——
    void minutelyPrecipReady(const QJsonObject &result);

    // —— Warnings / 实时预警 ——
    void warningNowReady(const QJsonObject &result);

    // —— Indices / 天气指数 ——
    void indicesReady(const QString &loc, const QJsonArray &daily);

    // —— Air quality / 空气质量 ——
    void airCurrentReady(const QString &cityId, const QJsonObject &result);
    void airHourlyReady(const QString &cityId, const QJsonObject &result);
    void airDailyReady(const QString &cityId, const QJsonObject &result);

    // —— Historical / 时光机 ——
    void historicalWeatherReady(const QJsonObject &result);
    void historicalAirReady(const QJsonObject &result);

    // —— Typhoon / 台风 ——
    void stormListReady(const QJsonArray &storms);
    void stormTrackReady(const QJsonObject &result);
    void stormForecastReady(const QJsonArray &forecast);

    // —— Ocean / 海洋 ——
    void oceanTideReady(const QJsonObject &result);

    // —— Solar radiation / 太阳辐射 ——
    void solarRadiationReady(const QString &cityId, const QJsonObject &result);

    // —— Astronomy / 天文 ——
    void astronomySunReady(const QString &cityId, const QJsonObject &result);
    void astronomyMoonReady(const QString &cityId, const QJsonObject &result);
    void solarElevationAngleReady(const QJsonObject &result);

private slots:
    // onReplyFinished — Unified reply handler, dispatches by ApiRequestType / 统一回复处理，按请求类型分发
    void onReplyFinished(QNetworkReply *reply);

private:
    // sendRequest — Build and send a QNetworkRequest / 构建并发送网络请求
    void sendRequest(const QUrl &url, ApiRequestType type);

    // Response handlers per API type / 各 API 类型的回复处理函数
    void handleCityLookup(const QByteArray &d);
    void handleCityTop(const QByteArray &d);
    void handleWeatherNow(const QByteArray &d, const QString &loc);
    void handleWeatherDaily(const QByteArray &d, const QString &loc);
    void handleWeatherHourly(const QByteArray &d, const QString &loc);
    void handleGridWeatherNow(const QByteArray &d, const QString &loc);
    void handleGridWeatherDaily(const QByteArray &d, const QString &loc);
    void handleGridWeatherHourly(const QByteArray &d, const QString &loc);
    void handleMinutelyPrecip(const QByteArray &d, const QString &loc);
    void handleWarningNow(const QByteArray &d, const QString &loc);
    void handleIndices(const QByteArray &d, const QString &loc);
    void handleAirCurrent(const QByteArray &d, const QString &loc);
    void handleAirHourly(const QByteArray &d, const QString &loc);
    void handleAirDaily(const QByteArray &d, const QString &loc);
    void handleHistoricalWeather(const QByteArray &d, const QString &loc);
    void handleHistoricalAir(const QByteArray &d, const QString &loc);
    void handleStormList(const QByteArray &d, const QString &loc);
    void handleStormTrack(const QByteArray &d, const QString &loc);
    void handleStormForecast(const QByteArray &d, const QString &loc);
    void handleOceanTide(const QByteArray &d, const QString &loc);
    void handleSolarRadiation(const QByteArray &d, const QString &loc);
    void handleAstronomySun(const QByteArray &d, const QString &loc);
    void handleAstronomyMoon(const QByteArray &d, const QString &loc);
    void handleSolarElevationAngle(const QByteArray &d, const QString &loc);

private:
    QNetworkAccessManager * m_manager;  // Network access manager / 网络访问管理器
    WeatherCache *m_cache = nullptr;    // Optional cache layer / 可选的缓存层
    QString m_key;           // API key set at runtime / 运行时设置的 API 密钥
    QString m_host;          // API base host set at runtime / 运行时设置的 API 基础地址
    int m_requestCount[24] = {0};  // Per-endpoint request counter / 各端点请求计数器
};





#endif // WEATHERAPI_H
