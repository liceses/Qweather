#include "CityDetailStore.h"
#include "weatherApi.h"
#include <QJsonDocument>
#include <QDate>
#include <QDebug>

// CityDetailStore — constructor, pre-init detail sections to avoid QML TypeError / 构造函数，预初始化各数据段避免 QML 访问 undefined
CityDetailStore::CityDetailStore(QObject* parent) : QObject(parent) {
    m_detail["now"] = QVariantMap();
    m_detail["air"] = QVariantMap();
    m_detail["daily"] = QVariantList();
    m_detail["hourly"] = QVariantList();
    m_detail["indices"] = QVariantList();
    m_detail["warnings"] = QVariantList();
    m_detail["sun"] = QVariantMap();
    m_detail["moon"] = QVariantMap();
    m_detail["solar"] = QVariantMap();
    m_detail["minutely"] = QVariantMap();
}

// setWeatherApi — inject API & connect all detail signals / 注入 API 并连接所有详情信号
void CityDetailStore::setWeatherApi(WeatherAPI* api) {
    if (m_api)
        disconnect(m_api, nullptr, this, nullptr);
    m_api = api;
    if (m_api) {
        connect(m_api, &WeatherAPI::weatherNowReady,
                this, &CityDetailStore::onWeatherNowReady);
        connect(m_api, &WeatherAPI::weatherDailyReady,
                this, &CityDetailStore::onWeatherDailyReady);
        connect(m_api, &WeatherAPI::weatherHourlyReady,
                this, &CityDetailStore::onWeatherHourlyReady);
        connect(m_api, &WeatherAPI::airCurrentReady,
                this, &CityDetailStore::onAirCurrentReady);
        connect(m_api, &WeatherAPI::indicesReady,
                this, &CityDetailStore::onIndicesReady);
        connect(m_api, &WeatherAPI::warningNowReady,
                this, &CityDetailStore::onWarningNowReady);
        connect(m_api, &WeatherAPI::astronomySunReady,
                this, &CityDetailStore::onAstronomySunReady);
        connect(m_api, &WeatherAPI::astronomyMoonReady,
                this, &CityDetailStore::onAstronomyMoonReady);
        connect(m_api, &WeatherAPI::solarRadiationReady,
                this, &CityDetailStore::onSolarRadiationReady);
        connect(m_api, &WeatherAPI::minutelyPrecipReady,
                this, &CityDetailStore::onMinutelyPrecipReady);
    }
}

// setCity — switch active city & fetch all data / 切换当前城市并拉取全部数据
void CityDetailStore::setCity(const QString& cityId, const QString& cityName,
                              const QString& lat, const QString& lon) {
    if (cityId.isEmpty()) {
        m_cityId.clear(); m_cityName.clear(); m_lat.clear(); m_lon.clear();
        m_detail.clear();
        emit hasCityChanged();
        emit detailChanged();
        return;
    }
    if (m_cityId == cityId && !m_detail.isEmpty()) return;

    m_cityId = cityId; m_cityName = cityName;
    m_lat = lat; m_lon = lon;
    m_detail.clear();
    m_detail["cityName"] = cityName;
    m_detail["cityId"] = cityId;
    // 预初始化全部数据段为空对象，避免 QML 访问 undefined 属性抛 TypeError
    m_detail["now"] = QVariantMap();
    m_detail["air"] = QVariantMap();
    m_detail["daily"] = QVariantList();
    m_detail["hourly"] = QVariantList();
    m_detail["indices"] = QVariantList();
    m_detail["warnings"] = QVariantList();
    m_detail["sun"] = QVariantMap();
    m_detail["moon"] = QVariantMap();
    m_detail["solar"] = QVariantMap();
    m_detail["minutely"] = QVariantMap();
    emit hasCityChanged();
    emit detailChanged();
    fetchAll();
}

// fetchAll — dispatch all API requests for current city / 发送当前城市所有 API 请求
void CityDetailStore::fetchAll() {
    if (!m_api || m_cityId.isEmpty()) return;

    QString today = QDate::currentDate().toString("yyyyMMdd");

    m_api->weatherNow(m_cityId);
    m_api->weatherDaily("3d", m_cityId);
    m_api->weatherHourly("24h", m_cityId);
    m_api->indices("1d", "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16", m_cityId);
    m_api->astronomySun(m_cityId, today, m_cityId);
    m_api->astronomyMoon(m_cityId, today, m_cityId);

    if (!m_lat.isEmpty() && !m_lon.isEmpty()) {
        m_api->airCurrent(m_lat, m_lon, m_cityId);
        m_api->warningNow(m_lat, m_lon);
        m_api->solarRadiation(m_lat, m_lon, m_cityId);
        m_api->minutelyPrecip(m_lat + "," + m_lon);
    }
}

// emitUpdated — trigger QML binding by signalling detailChanged / 触发 QML 绑定刷新
void CityDetailStore::emitUpdated() {
    emit detailChanged();
}

// ---- 处理器 / Handlers ----

// onWeatherNowReady — handle real-time weather / 处理实况天气
void CityDetailStore::onWeatherNowReady(const QJsonObject& obj) {
    if (obj["_location"].toString() != m_cityId) return;
    QVariantMap now;
    now["temp"] = obj["temp"].toString();
    now["feelsLike"] = obj["feelsLike"].toString();
    now["icon"] = obj["icon"].toString();
    now["text"] = obj["text"].toString();
    now["windDir"] = obj["windDir"].toString();
    now["windSpeed"] = obj["windSpeed"].toString();
    now["windScale"] = obj["windScale"].toString();
    now["humidity"] = obj["humidity"].toString();
    now["precip"] = obj["precip"].toString();
    now["pressure"] = obj["pressure"].toString();
    now["vis"] = obj["vis"].toString();
    now["cloud"] = obj["cloud"].toString();
    now["dew"] = obj["dew"].toString();

    QVariantMap d = m_detail; d["now"] = now; m_detail = d;
    qDebug() << "[CityDetail] now ready:" << now["temp"].toString() << "°C";
    emitUpdated();
}

// onWeatherDailyReady — handle daily forecast / 处理逐天预报
void CityDetailStore::onWeatherDailyReady(const QString& loc, const QJsonArray& arr) {
    if (loc != m_cityId) return;
    QVariantList daily;
    for (const QJsonValue& v : arr) {
        QJsonObject o = v.toObject();
        QVariantMap d;
        d["fxDate"] = o["fxDate"].toString();
        d["tempMax"] = o["tempMax"].toString();
        d["tempMin"] = o["tempMin"].toString();
        d["iconDay"] = o["iconDay"].toString();
        d["textDay"] = o["textDay"].toString();
        d["iconNight"] = o["iconNight"].toString();
        d["textNight"] = o["textNight"].toString();
        d["windDirDay"] = o["windDirDay"].toString();
        d["windScaleDay"] = o["windScaleDay"].toString();
        d["humidity"] = o["humidity"].toString();
        d["precip"] = o["precip"].toString();
        d["uvIndex"] = o["uvIndex"].toString();
        d["sunrise"] = o["sunrise"].toString();
        d["sunset"] = o["sunset"].toString();
        d["moonPhase"] = o["moonPhase"].toString();
        daily.append(d);
    }

    QVariantMap dm = m_detail; dm["daily"] = daily; m_detail = dm;
    qDebug() << "[CityDetail] daily ready:" << daily.size() << "days";
    emitUpdated();
}

// onWeatherHourlyReady — handle hourly forecast / 处理逐小时预报
void CityDetailStore::onWeatherHourlyReady(const QString& loc, const QJsonArray& arr) {
    if (loc != m_cityId) return;
    QVariantList hourly;
    for (const QJsonValue& v : arr) {
        QJsonObject o = v.toObject();
        QVariantMap h;
        h["fxTime"] = o["fxTime"].toString();
        h["temp"] = o["temp"].toString();
        h["icon"] = o["icon"].toString();
        h["text"] = o["text"].toString();
        h["windDir"] = o["windDir"].toString();
        h["windScale"] = o["windScale"].toString();
        h["humidity"] = o["humidity"].toString();
        h["pop"] = o["pop"].toString();
        h["precip"] = o["precip"].toString();
        hourly.append(h);
    }

    QVariantMap dm = m_detail; dm["hourly"] = hourly; m_detail = dm;
    qDebug() << "[CityDetail] hourly ready:" << hourly.size() << "hours";
    emitUpdated();
}

// onAirCurrentReady — handle air quality / 处理空气质量
void CityDetailStore::onAirCurrentReady(const QString& cityId, const QJsonObject& obj) {
    if (cityId != m_cityId) return;

    QJsonArray indexes = obj["indexes"].toArray();
    QJsonObject bestIndex;
    for (const QJsonValue& v : indexes) {
        QJsonObject idx = v.toObject();
        if (idx["code"].toString() == "us-epa") { bestIndex = idx; break; }
    }
    if (bestIndex.isEmpty() && !indexes.isEmpty())
        bestIndex = indexes.first().toObject();

    QString primaryPollutant;
    QJsonObject pp = bestIndex["primaryPollutant"].toObject();
    if (!pp.isEmpty()) primaryPollutant = pp["name"].toString();

    QJsonObject colorObj = bestIndex["color"].toObject();
    QString colorHex = "#00e400";
    if (!colorObj.isEmpty()) {
        colorHex = QString("#%1%2%3")
            .arg(colorObj["red"].toInt(), 2, 16, QLatin1Char('0'))
            .arg(colorObj["green"].toInt(), 2, 16, QLatin1Char('0'))
            .arg(colorObj["blue"].toInt(), 2, 16, QLatin1Char('0'));
    }

    QVariantList pollutants;
    QJsonArray pollArr = obj["pollutants"].toArray();
    for (const QJsonValue& v : pollArr) {
        QJsonObject p = v.toObject();
        QJsonObject conc = p["concentration"].toObject();
        QVariantMap pm;
        pm["name"] = p["name"].toString();
        pm["value"] = conc["value"].toDouble();
        pm["unit"] = conc["unit"].toString();
        pollutants.append(pm);
    }

    QVariantMap air;
    air["aqi"] = bestIndex["aqiDisplay"].toString();
    air["level"] = bestIndex["level"].toString();
    air["category"] = bestIndex["category"].toString();
    air["primaryPollutant"] = primaryPollutant;
    air["color"] = colorHex;
    air["pollutants"] = pollutants;

    QJsonObject health = bestIndex["health"].toObject();
    QJsonObject advice = health["advice"].toObject();
    air["healthEffect"] = health["effect"].toString();
    air["healthAdvice"] = advice["generalPopulation"].toString();

    QVariantMap dm = m_detail; dm["air"] = air; m_detail = dm;
    qDebug() << "[CityDetail] air ready: AQI" << air["aqi"].toString();
    emitUpdated();
}

// onIndicesReady — handle weather indices / 处理天气指数
void CityDetailStore::onIndicesReady(const QString& loc, const QJsonArray& arr) {
    if (loc != m_cityId) return;
    QVariantList indices;
    for (const QJsonValue& v : arr) {
        QJsonObject o = v.toObject();
        QVariantMap idx;
        idx["name"] = o["name"].toString();
        idx["level"] = o["level"].toString();
        idx["category"] = o["category"].toString();
        idx["text"] = o["text"].toString();
        indices.append(idx);
    }

    QVariantMap dm = m_detail; dm["indices"] = indices; m_detail = dm;
    qDebug() << "[CityDetail] indices ready:" << indices.size();
    emitUpdated();
}

// onWarningNowReady — handle weather alerts / 处理天气预警
void CityDetailStore::onWarningNowReady(const QJsonObject& obj) {
    QJsonArray alerts = obj["alerts"].toArray();
    QVariantList warnings;
    for (const QJsonValue& v : alerts) {
        QJsonObject a = v.toObject();
        QVariantMap w;
        w["headline"] = a["headline"].toString();
        w["severity"] = a["severity"].toString();
        w["description"] = a["description"].toString();
        w["instruction"] = a["instruction"].toString();
        w["expireTime"] = a["expireTime"].toString();
        w["effectiveTime"] = a["effectiveTime"].toString();

        QJsonObject eventType = a["eventType"].toObject();
        w["eventName"] = eventType["name"].toString();

        QJsonObject colorObj = a["color"].toObject();
        if (!colorObj.isEmpty()) {
            w["severityColor"] = QString("#%1%2%3")
                .arg(colorObj["red"].toInt(), 2, 16, QLatin1Char('0'))
                .arg(colorObj["green"].toInt(), 2, 16, QLatin1Char('0'))
                .arg(colorObj["blue"].toInt(), 2, 16, QLatin1Char('0'));
        }
        warnings.append(w);
    }

    if (warnings.isEmpty()) return;

    QVariantMap dm = m_detail; dm["warnings"] = warnings; m_detail = dm;
    qDebug() << "[CityDetail] warnings ready:" << warnings.size();
    emitUpdated();
}

// onAstronomySunReady — handle sunrise/sunset / 处理日出日落
void CityDetailStore::onAstronomySunReady(const QString& cityId, const QJsonObject& obj) {
    if (cityId != m_cityId) return;
    QVariantMap sun;
    sun["sunrise"] = obj["sunrise"].toString();
    sun["sunset"] = obj["sunset"].toString();

    QVariantMap dm = m_detail; dm["sun"] = sun; m_detail = dm;
    qDebug() << "[CityDetail] sun ready";
    emitUpdated();
}

// onAstronomyMoonReady — handle moon phase / 处理月相
void CityDetailStore::onAstronomyMoonReady(const QString& cityId, const QJsonObject& obj) {
    if (cityId != m_cityId) return;
    QVariantMap moon;
    QJsonArray phases = obj["moonPhase"].toArray();
    if (!phases.isEmpty()) {
        QJsonObject mp = phases.first().toObject();
        moon["moonPhase"] = mp["name"].toString();
        moon["moonIcon"] = mp["icon"].toString();
        moon["moonIllumination"] = mp["illumination"].toString();
    }
    moon["moonrise"] = obj["moonrise"].toString();
    moon["moonset"] = obj["moonset"].toString();

    QVariantMap dm = m_detail; dm["moon"] = moon; m_detail = dm;
    qDebug() << "[CityDetail] moon ready:" << moon["moonPhase"].toString();
    emitUpdated();
}

// onSolarRadiationReady — handle solar radiation / 处理太阳辐射
void CityDetailStore::onSolarRadiationReady(const QString& cityId, const QJsonObject& obj) {
    if (cityId != m_cityId) return;
    QJsonArray forecasts = obj["forecasts"].toArray();
    QVariantMap solar;
    if (!forecasts.isEmpty()) {
        QJsonObject f0 = forecasts.first().toObject();

        QJsonObject ghiObj = f0["ghi"].toObject();
        solar["ghi"] = ghiObj["value"].toDouble();
        solar["ghiUnit"] = ghiObj["unit"].toString();

        QJsonObject dniObj = f0["dni"].toObject();
        solar["dni"] = dniObj["value"].toDouble();
        solar["dniUnit"] = dniObj["unit"].toString();

        QJsonObject dhiObj = f0["dhi"].toObject();
        solar["dhi"] = dhiObj["value"].toDouble();
        solar["dhiUnit"] = dhiObj["unit"].toString();

        QJsonObject angle = f0["solarAngle"].toObject();
        solar["solarAzimuth"] = angle["azimuth"].toDouble();
        solar["solarElevation"] = angle["elevation"].toDouble();
    }

    QVariantMap dm = m_detail; dm["solar"] = solar; m_detail = dm;
    qDebug() << "[CityDetail] solar ready: GHI" << solar["ghi"].toDouble();
    emitUpdated();
}

// onMinutelyPrecipReady — handle minutely precipitation / 处理分钟级降水
void CityDetailStore::onMinutelyPrecipReady(const QJsonObject& obj) {
    // 过滤：_location 为 "lat,lng" 格式
    QString expectedLoc = m_lat + "," + m_lon;
    if (m_lat.isEmpty() || obj["_location"].toString() != expectedLoc) return;

    QVariantMap minutely;
    minutely["summary"] = obj["summary"].toString();

    QVariantList items;
    QJsonArray arr = obj["minutely"].toArray();
    for (const QJsonValue& v : arr) {
        QJsonObject o = v.toObject();
        QVariantMap item;
        item["fxTime"] = o["fxTime"].toString();
        item["precip"] = o["precip"].toString();
        item["type"] = o["type"].toString();
        items.append(item);
    }
    minutely["items"] = items;

    QVariantMap dm = m_detail; dm["minutely"] = minutely; m_detail = dm;
    qDebug() << "[CityDetail] minutely ready:" << items.size() << "steps";
    emitUpdated();
}
