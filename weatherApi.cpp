#include "weatherApi.h"
#include "WeatherCache.h"
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QUrlQuery>
#include <QDebug>

// 缓存配置：{ prefix, TTL秒 }
struct CacheConf { const char* prefix; int ttl; };
static CacheConf cacheConf(ApiRequestType t) {
    switch (t) {
    case ApiRequestType::WeatherNow:         return {"weather_now", 600};
    case ApiRequestType::WeatherDaily:       return {"weather_daily", 3600};
    case ApiRequestType::WeatherHourly:      return {"weather_hourly", 1800};
    case ApiRequestType::GridWeatherNow:     return {"grid_now", 600};
    case ApiRequestType::GridWeatherDaily:   return {"grid_daily", 3600};
    case ApiRequestType::GridWeatherHourly:  return {"grid_hourly", 1800};
    case ApiRequestType::MinutelyPrecip:     return {"minutely", 300};
    case ApiRequestType::WarningNow:         return {"warning", 300};
    case ApiRequestType::Indices:            return {"indices", 3600};
    case ApiRequestType::AirCurrent:         return {"air_current", 1800};
    case ApiRequestType::AirHourly:          return {"air_hourly", 3600};
    case ApiRequestType::AirDaily:           return {"air_daily", 3600};
    case ApiRequestType::HistoricalWeather:  return {"hist_weather", 86400};
    case ApiRequestType::HistoricalAir:      return {"hist_air", 86400};
    case ApiRequestType::StormList:          return {"storm_list", 3600};
    case ApiRequestType::StormTrack:         return {"storm_track", 600};
    case ApiRequestType::StormForecast:      return {"storm_forecast", 600};
    case ApiRequestType::OceanTide:          return {"tide", 600};
    case ApiRequestType::SolarRadiation:     return {"solar", 3600};
    case ApiRequestType::AstronomySun:       return {"astro_sun", 86400};
    case ApiRequestType::AstronomyMoon:      return {"astro_moon", 86400};
    case ApiRequestType::SolarElevationAngle:return {"solar_angle", 3600};
    case ApiRequestType::CityLookup:         return {"city_lookup", 86400};
    case ApiRequestType::CityTop:            return {"city_top", 86400};
    default: return {nullptr, 0};
    }
}

WeatherAPI::WeatherAPI(QObject *parent) : QObject(parent) , m_manager(new QNetworkAccessManager(this))
{
    connect(m_manager,&QNetworkAccessManager::finished,this,&WeatherAPI::onReplyFinished);
}

// ============================ GeoAPI ============================

void WeatherAPI::searchCity(const QString &name)
{
    if (m_cache) {
        auto cc = cacheConf(ApiRequestType::CityLookup);
        QString key = QString("%1:%2").arg(cc.prefix, name);
        QString c = m_cache->get(key, cc.ttl);
        if (!c.isEmpty()) {
            QJsonArray arr = QJsonDocument::fromJson(c.toUtf8()).object()["location"].toArray();
            if (!arr.isEmpty()) { emit cityLookupReady(arr); return; }
        }
    }
    QUrl url(m_host + "/geo/v2/city/lookup");
    QUrlQuery q;
    q.addQueryItem("location", name);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::CityLookup);
}

void WeatherAPI::topCity(const QString &range, int number)
{
    if (m_cache) {
        auto cc = cacheConf(ApiRequestType::CityTop);
        QString key = QString("%1:%2").arg(cc.prefix, range);
        QString c = m_cache->get(key, cc.ttl);
        if (!c.isEmpty()) {
            QJsonArray arr = QJsonDocument::fromJson(c.toUtf8()).object()["topCityList"].toArray();
            emit cityTopReady(arr);
            return;
        }
    }
    QUrl url(m_host + "/geo/v2/city/top");
    QUrlQuery q;
    q.addQueryItem("range", range);
    q.addQueryItem("number", QString::number(number));
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::CityTop);
}

// ============================ 天气预报 ============================

void WeatherAPI::weatherNow(const QString &loc)
{
    if (m_cache) {
        auto cc = cacheConf(ApiRequestType::WeatherNow);
        QString key = QString("%1:%2").arg(cc.prefix, loc);
        QString c = m_cache->get(key, cc.ttl);
        if (!c.isEmpty()) { handleWeatherNow(c.toUtf8(), loc); return; }
    }
    QUrl url(m_host + "/v7/weather/now");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::WeatherNow);
}

void WeatherAPI::weatherDaily(const QString &days, const QString &loc)
{
    QUrl url(m_host + "/v7/weather/" + days);
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    if (m_cache) {
        auto cc = cacheConf(ApiRequestType::WeatherDaily);
        QString key = QString("%1:%2:%3").arg(cc.prefix, days, loc);
        QString c = m_cache->get(key, cc.ttl);
        if (!c.isEmpty()) { handleWeatherDaily(c.toUtf8(), loc); return; }
    }
    sendRequest(url, ApiRequestType::WeatherDaily);
}

void WeatherAPI::weatherHourly(const QString &hours, const QString &loc)
{
    QUrl url(m_host + "/v7/weather/" + hours);
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::WeatherHourly);
}

// ============================ 格点天气预报 ============================

void WeatherAPI::gridWeatherNow(const QString &loc)
{
    QUrl url(m_host + "/v7/grid-weather/now");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::GridWeatherNow);
}

void WeatherAPI::gridWeatherDaily(const QString &days, const QString &loc)
{
    QUrl url(m_host + "/v7/grid-weather/" + days);
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::GridWeatherDaily);
}

void WeatherAPI::gridWeatherHourly(const QString &hours, const QString &loc)
{
    QUrl url(m_host + "/v7/grid-weather/" + hours);
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::GridWeatherHourly);
}

// ============================ 分钟预报 ============================

void WeatherAPI::minutelyPrecip(const QString &loc)
{
    QUrl url(m_host + "/v7/minutely/5m");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::MinutelyPrecip);
}

// ============================ 预警 (v1) ============================

void WeatherAPI::warningNow(const QString &lat, const QString &lng)
{
    QUrl url(m_host + "/weatheralert/v1/current/" + lat + "/" + lng);
    QUrlQuery q;
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::WarningNow);
}

// ============================ 天气指数 ============================

void WeatherAPI::indices(const QString &days, const QString &type, const QString &loc)
{
    QUrl url(m_host + "/v7/indices/" + days);
    QUrlQuery q;
    q.addQueryItem("type", type);
    q.addQueryItem("location", loc);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::Indices);
}

// ============================ 空气质量 ============================

void WeatherAPI::airCurrent(const QString &lat, const QString &lng)
{
    QUrl url(m_host + "/airquality/v1/current/" + lat + "/" + lng);
    QUrlQuery q;
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::AirCurrent);
}

void WeatherAPI::airHourly(const QString &lat, const QString &lng)
{
    QUrl url(m_host + "/airquality/v1/hourly/" + lat + "/" + lng);
    QUrlQuery q;
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::AirHourly);
}

void WeatherAPI::airDaily(const QString &lat, const QString &lng)
{
    QUrl url(m_host + "/airquality/v1/daily/" + lat + "/" + lng);
    QUrlQuery q;
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::AirDaily);
}

// ============================ 时光机 ============================

void WeatherAPI::historicalWeather(const QString &loc, const QString &date)
{
    QUrl url(m_host + "/v7/historical/weather");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("date", date);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::HistoricalWeather);
}

void WeatherAPI::historicalAir(const QString &loc, const QString &date)
{
    QUrl url(m_host + "/v7/historical/air");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("date", date);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::HistoricalAir);
}

// ============================ 热带气旋 ============================

void WeatherAPI::stormList(const QString &basin, const QString &year)
{
    QUrl url(m_host + "/v7/tropical/storm-list");
    QUrlQuery q;
    q.addQueryItem("basin", basin);
    q.addQueryItem("key", m_key);
    if (!year.isEmpty()) q.addQueryItem("year", year);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::StormList);
}

void WeatherAPI::stormTrack(const QString &sid)
{
    QUrl url(m_host + "/v7/tropical/storm-track");
    QUrlQuery q;
    q.addQueryItem("stormid", sid);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::StormTrack);
}

void WeatherAPI::stormForecast(const QString &sid)
{
    QUrl url(m_host + "/v7/tropical/storm-forecast");
    QUrlQuery q;
    q.addQueryItem("stormid", sid);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::StormForecast);
}

// ============================ 海洋数据 ============================

void WeatherAPI::oceanTide(const QString &loc, const QString &date)
{
    QUrl url(m_host + "/v7/ocean/tide");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("date", date);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::OceanTide);
}

// ============================ 太阳辐射 ============================

void WeatherAPI::solarRadiation(const QString &lat, const QString &lng,
                                int hours, int interval)
{
    QUrl url(m_host + "/solarradiation/v1/forecast/" + lat + "/" + lng);
    QUrlQuery q;
    q.addQueryItem("hours", QString::number(hours));
    q.addQueryItem("interval", QString::number(interval));
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::SolarRadiation);
}

// ============================ 天文 ============================

void WeatherAPI::astronomySun(const QString &loc, const QString &date)
{
    QUrl url(m_host + "/v7/astronomy/sun");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("date", date);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::AstronomySun);
}

void WeatherAPI::astronomyMoon(const QString &loc, const QString &date)
{
    QUrl url(m_host + "/v7/astronomy/moon");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("date", date);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::AstronomyMoon);
}

void WeatherAPI::solarElevAngle(const QString &loc, const QString &date,
                                const QString &time, const QString &tz, const QString &alt)
{
    QUrl url(m_host + "/v7/astronomy/solar-elevation-angle");
    QUrlQuery q;
    q.addQueryItem("location", loc);
    q.addQueryItem("date", date);
    q.addQueryItem("time", time);
    q.addQueryItem("tz", tz);
    q.addQueryItem("alt", alt);
    q.addQueryItem("key", m_key);
    url.setQuery(q);
    sendRequest(url, ApiRequestType::SolarElevationAngle);
}


// ============================ 统一路由 ============================

void WeatherAPI::onReplyFinished(QNetworkReply *reply)
{
    QByteArray data = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        emit ErrorOccured(reply->errorString());
        return;
    }

    auto type = static_cast<ApiRequestType>(
        reply->request().attribute(QNetworkRequest::User).toInt());
    QUrlQuery q(reply->request().url());
    QString loc = q.queryItemValue("location");

    // 写入缓存
    if (m_cache) {
        auto cc = cacheConf(type);
        if (cc.prefix && !loc.isEmpty()) {
            QString key = QString("%1:%2").arg(cc.prefix, loc);
            m_cache->set(key, QString::fromUtf8(data));
        }
    }

    switch (type) {
    case ApiRequestType::CityLookup:           handleCityLookup(data);           break;
    case ApiRequestType::CityTop:              handleCityTop(data);              break;
    case ApiRequestType::WeatherNow:           handleWeatherNow(data, loc);           break;
    case ApiRequestType::WeatherDaily:         handleWeatherDaily(data, loc);         break;
    case ApiRequestType::WeatherHourly:        handleWeatherHourly(data, loc);        break;
    case ApiRequestType::GridWeatherNow:       handleGridWeatherNow(data, loc);       break;
    case ApiRequestType::GridWeatherDaily:     handleGridWeatherDaily(data, loc);     break;
    case ApiRequestType::GridWeatherHourly:    handleGridWeatherHourly(data, loc);    break;
    case ApiRequestType::MinutelyPrecip:       handleMinutelyPrecip(data, loc);       break;
    case ApiRequestType::WarningNow:           handleWarningNow(data, loc);           break;
    case ApiRequestType::Indices:              handleIndices(data, loc);              break;
    case ApiRequestType::AirCurrent:           handleAirCurrent(data, loc);           break;
    case ApiRequestType::AirHourly:            handleAirHourly(data, loc);            break;
    case ApiRequestType::AirDaily:             handleAirDaily(data, loc);             break;
    case ApiRequestType::HistoricalWeather:    handleHistoricalWeather(data, loc);    break;
    case ApiRequestType::HistoricalAir:        handleHistoricalAir(data, loc);        break;
    case ApiRequestType::StormList:            handleStormList(data, loc);            break;
    case ApiRequestType::StormTrack:           handleStormTrack(data, loc);           break;
    case ApiRequestType::StormForecast:        handleStormForecast(data, loc);        break;
    case ApiRequestType::OceanTide:            handleOceanTide(data, loc);            break;
    case ApiRequestType::SolarRadiation:       handleSolarRadiation(data, loc);       break;
    case ApiRequestType::AstronomySun:         handleAstronomySun(data, loc);         break;
    case ApiRequestType::AstronomyMoon:        handleAstronomyMoon(data, loc);        break;
    case ApiRequestType::SolarElevationAngle:  handleSolarElevationAngle(data, loc);  break;
    }
}
void WeatherAPI::sendRequest(const QUrl &url, ApiRequestType type)
{
    QNetworkRequest req(url);
    req.setRawHeader("Accept", "application/json");
    req.setAttribute(QNetworkRequest::User, static_cast<int>(type));
    m_manager->get(req);
}

// ============================ Handler 函数 ============================

void WeatherAPI::handleCityLookup(const QByteArray &d)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["location"].toArray();
    if (arr.isEmpty()) { emit ErrorOccured("城市未找到"); return; }
    emit cityLookupReady(arr);
}

void WeatherAPI::handleCityTop(const QByteArray &d)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["topCityList"].toArray();
    emit cityTopReady(arr);
}

void WeatherAPI::handleWeatherNow(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object()["now"].toObject();
    obj["_location"] = loc;
    emit weatherNowReady(obj);
}

void WeatherAPI::handleWeatherDaily(const QByteArray &d, const QString &loc)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["daily"].toArray();
    emit weatherDailyReady(loc, arr);
}

void WeatherAPI::handleWeatherHourly(const QByteArray &d, const QString &loc)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["hourly"].toArray();
    emit weatherHourlyReady(loc, arr);
}

void WeatherAPI::handleGridWeatherNow(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object()["now"].toObject();
    obj["_location"] = loc;
    emit gridWeatherNowReady(obj);
}

void WeatherAPI::handleGridWeatherDaily(const QByteArray &d, const QString &loc)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["daily"].toArray();
    emit gridWeatherDailyReady(loc, arr);
}

void WeatherAPI::handleGridWeatherHourly(const QByteArray &d, const QString &loc)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["hourly"].toArray();
    emit gridWeatherHourlyReady(loc, arr);
}

void WeatherAPI::handleMinutelyPrecip(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit minutelyPrecipReady(obj);
}

void WeatherAPI::handleWarningNow(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit warningNowReady(obj);
}

void WeatherAPI::handleIndices(const QByteArray &d, const QString &loc)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["daily"].toArray();
    emit indicesReady(loc, arr);
}

void WeatherAPI::handleAirCurrent(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit airCurrentReady(obj);
}

void WeatherAPI::handleAirHourly(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit airHourlyReady(obj);
}

void WeatherAPI::handleAirDaily(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit airDailyReady(obj);
}

void WeatherAPI::handleHistoricalWeather(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit historicalWeatherReady(obj);
}

void WeatherAPI::handleHistoricalAir(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit historicalAirReady(obj);
}

void WeatherAPI::handleStormList(const QByteArray &d, const QString &loc)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["storm"].toArray();
    emit stormListReady(arr);
}

void WeatherAPI::handleStormTrack(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit stormTrackReady(obj);
}

void WeatherAPI::handleStormForecast(const QByteArray &d, const QString &loc)
{
    QJsonArray arr = QJsonDocument::fromJson(d).object()["forecast"].toArray();
    emit stormForecastReady(arr);
}

void WeatherAPI::handleOceanTide(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit oceanTideReady(obj);
}

void WeatherAPI::handleSolarRadiation(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit solarRadiationReady(obj);
}

void WeatherAPI::handleAstronomySun(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit astronomySunReady(obj);
}

void WeatherAPI::handleAstronomyMoon(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit astronomyMoonReady(obj);
}

void WeatherAPI::handleSolarElevationAngle(const QByteArray &d, const QString &loc)
{
    QJsonObject obj = QJsonDocument::fromJson(d).object();
    obj["_location"] = loc;
    emit solarElevationAngleReady(obj);
}