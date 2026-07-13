#ifndef WEATHERAPI_H
#define WEATHERAPI_H
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class WeatherCache;

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

class WeatherAPI :public QObject{
    Q_OBJECT
public:
    explicit WeatherAPI(QObject* parent = nullptr);
    void setCache(WeatherCache *cache) { m_cache = cache; }

    // Q_INVOKABLE = 这个函数可以被 QML 直接调用
    // GeoAPI
    Q_INVOKABLE void searchCity(const QString &name);
    Q_INVOKABLE void topCity(const QString &range = "cn", int number = 10);
    // 天气预报
    Q_INVOKABLE void weatherNow(const QString &loc);
    Q_INVOKABLE void weatherDaily(const QString &days, const QString &loc);
    Q_INVOKABLE void weatherHourly(const QString &hours, const QString &loc);
    // 格点天气
    Q_INVOKABLE void gridWeatherNow(const QString &loc);
    Q_INVOKABLE void gridWeatherDaily(const QString &days, const QString &loc);
    Q_INVOKABLE void gridWeatherHourly(const QString &hours, const QString &loc);
    // 分钟降水
    Q_INVOKABLE void minutelyPrecip(const QString &loc);
    // 预警 (v1)
    Q_INVOKABLE void warningNow(const QString &lat, const QString &lng);
    // 天气指数
    Q_INVOKABLE void indices(const QString &days, const QString &type, const QString &loc);
    // 空气质量
    Q_INVOKABLE void airCurrent(const QString &lat, const QString &lng);
    Q_INVOKABLE void airHourly(const QString &lat, const QString &lng);
    Q_INVOKABLE void airDaily(const QString &lat, const QString &lng);
    // 时光机
    Q_INVOKABLE void historicalWeather(const QString &loc, const QString &date);
    Q_INVOKABLE void historicalAir(const QString &loc, const QString &date);
    // 台风
    Q_INVOKABLE void stormList(const QString &basin, const QString &year = "");
    Q_INVOKABLE void stormTrack(const QString &sid);
    Q_INVOKABLE void stormForecast(const QString &sid);
    // 海洋
    Q_INVOKABLE void oceanTide(const QString &loc, const QString &date);
    // 太阳辐射
    Q_INVOKABLE void solarRadiation(const QString &lat, const QString &lng,
                                    int hours = 24, int interval = 60);
    // 天文
    Q_INVOKABLE void astronomySun(const QString &loc, const QString &date);
    Q_INVOKABLE void astronomyMoon(const QString &loc, const QString &date);
    Q_INVOKABLE void solarElevAngle(const QString &loc, const QString &date,
                                    const QString &time, const QString &tz, const QString &alt);


signals:
    // 查询完成后发出信号，QML 端自动收到
    void ErrorOccured(const QString &err);
    // GeoAPI
    void cityLookupReady(const QJsonArray &locations);
    void cityTopReady(const QJsonArray &cities);
    // 天气预报
    void weatherNowReady(const QJsonObject &now);
    void weatherDailyReady(const QString &loc, const QJsonArray &daily);
    void weatherHourlyReady(const QString &loc, const QJsonArray &hourly);
    // 格点天气
    void gridWeatherNowReady(const QJsonObject &now);
    void gridWeatherDailyReady(const QString &loc, const QJsonArray &daily);
    void gridWeatherHourlyReady(const QString &loc, const QJsonArray &hourly);
    // 分钟降水
    void minutelyPrecipReady(const QJsonObject &result);
    // 预警
    void warningNowReady(const QJsonObject &result);
    // 天气指数
    void indicesReady(const QString &loc, const QJsonArray &daily);
    // 空气质量
    void airCurrentReady(const QJsonObject &result);
    void airHourlyReady(const QJsonObject &result);
    void airDailyReady(const QJsonObject &result);
    // 时光机
    void historicalWeatherReady(const QJsonObject &result);
    void historicalAirReady(const QJsonObject &result);
    // 台风
    void stormListReady(const QJsonArray &storms);
    void stormTrackReady(const QJsonObject &result);
    void stormForecastReady(const QJsonArray &forecast);
    // 海洋
    void oceanTideReady(const QJsonObject &result);
    // 太阳辐射
    void solarRadiationReady(const QJsonObject &result);
    // 天文
    void astronomySunReady(const QJsonObject &result);
    void astronomyMoonReady(const QJsonObject &result);
    void solarElevationAngleReady(const QJsonObject &result);

private slots:
    void onReplyFinished(QNetworkReply *reply);

private:
    void sendRequest(const QUrl &url, ApiRequestType type);
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
    QNetworkAccessManager * m_manager;
    WeatherCache *m_cache = nullptr;
    const QString m_key = "ac6fe42e65be4a79a9eca8fc5043c2bf";
    QString m_host = "https://kc2k5qe8b5.re.qweatherapi.com";
};





#endif // WEATHERAPI_H
