#include "SolarAstronomyStore.h"
#include "weatherApi.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QDate>
#include <QDebug>

SolarAstronomyStore::SolarAstronomyStore(QObject* parent) : QObject(parent) {}

void SolarAstronomyStore::setWeatherApi(WeatherAPI* api) {
    if (m_api)
        disconnect(m_api, nullptr, this, nullptr);
    m_api = api;
    if (m_api) {
        connect(m_api, &WeatherAPI::solarRadiationReady,
                this, &SolarAstronomyStore::onSolarRadiationReady);
        connect(m_api, &WeatherAPI::astronomySunReady,
                this, &SolarAstronomyStore::onAstronomySunReady);
        connect(m_api, &WeatherAPI::astronomyMoonReady,
                this, &SolarAstronomyStore::onAstronomyMoonReady);
    }
}

void SolarAstronomyStore::setCities(const QVariantList& cities) {
    m_cities = cities;
    qDebug() << "[SolarAstronomy] setCities count:" << m_cities.size();
    emit citiesChanged();
    refreshAll();
}

void SolarAstronomyStore::refreshAll() {
    if (!m_api || m_cities.isEmpty()) {
        qDebug() << "[SolarAstronomy] refreshAll skip: api=" << (m_api != nullptr) << "cities=" << m_cities.size();
        return;
    }
    int count = qMin(m_cities.size(), 4);
    QString today = QDate::currentDate().toString("yyyyMMdd");
    qDebug() << "[SolarAstronomy] refreshAll count=" << count << "date=" << today;
    for (int i = 0; i < count; ++i) {
        QVariantMap city = m_cities[i].toMap();
        QString id = city["id"].toString();
        QString lat = city["lat"].toString();
        QString lon = city["lon"].toString();
        QString name = city["name"].toString();
        qDebug() << "[SolarAstronomy]   requesting for" << name << id << "lat:" << lat << "lon:" << lon;
        if (!lat.isEmpty() && !lon.isEmpty()) {
            m_api->solarRadiation(lat, lon, id);
            m_api->astronomySun(id, today, id);
            m_api->astronomyMoon(id, today, id);
        }
    }
}

// ---- 太阳辐射 handler ----

void SolarAstronomyStore::onSolarRadiationReady(const QString& cityId, const QJsonObject& result) {
    QJsonArray forecasts = result["forecasts"].toArray();
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

    QVariantMap raw = m_solarRaw[cityId].toMap();
    raw["solar"] = solar;
    m_solarRaw[cityId] = raw;

    qDebug() << "[SolarAstronomy] solarReady" << cityId << "GHI:" << solar["ghi"].toDouble();
    mergeAndEmit(cityId);
}

// ---- 日出日落 handler ----

void SolarAstronomyStore::onAstronomySunReady(const QString& cityId, const QJsonObject& result) {
    QVariantMap sun;
    sun["sunrise"] = result["sunrise"].toString();
    sun["sunset"] = result["sunset"].toString();

    QVariantMap raw = m_solarRaw[cityId].toMap();
    raw["sun"] = sun;
    m_solarRaw[cityId] = raw;

    qDebug() << "[SolarAstronomy] sunReady" << cityId << "sunrise:" << sun["sunrise"].toString();
    mergeAndEmit(cityId);
}

// ---- 月相 handler ----

void SolarAstronomyStore::onAstronomyMoonReady(const QString& cityId, const QJsonObject& result) {
    QVariantMap moon;
    QJsonArray phases = result["moonPhase"].toArray();
    if (!phases.isEmpty()) {
        QJsonObject mp = phases.first().toObject();
        moon["moonPhase"] = mp["name"].toString();
        moon["moonIcon"] = mp["icon"].toString();
        moon["moonIllumination"] = mp["illumination"].toString();
    }
    moon["moonrise"] = result["moonrise"].toString();
    moon["moonset"] = result["moonset"].toString();

    QVariantMap raw = m_solarRaw[cityId].toMap();
    raw["moon"] = moon;
    m_solarRaw[cityId] = raw;

    qDebug() << "[SolarAstronomy] moonReady" << cityId << "phase:" << moon["moonPhase"].toString();
    mergeAndEmit(cityId);
}

// ---- 合并 3 个 API 结果，写入最终数据 ----

void SolarAstronomyStore::mergeAndEmit(const QString& cityId) {
    QVariantMap raw = m_solarRaw[cityId].toMap();
    QVariantMap solar = raw["solar"].toMap();
    QVariantMap sun = raw["sun"].toMap();
    QVariantMap moon = raw["moon"].toMap();

    QVariantMap entry;
    entry["ghi"] = solar["ghi"];
    entry["dni"] = solar["dni"];
    entry["dhi"] = solar["dhi"];
    entry["ghiUnit"] = solar["ghiUnit"];
    entry["dniUnit"] = solar["dniUnit"];
    entry["dhiUnit"] = solar["dhiUnit"];
    entry["solarAzimuth"] = solar["solarAzimuth"];
    entry["solarElevation"] = solar["solarElevation"];
    entry["sunrise"] = sun["sunrise"];
    entry["sunset"] = sun["sunset"];
    entry["moonPhase"] = moon["moonPhase"];
    entry["moonIcon"] = moon["moonIcon"];
    entry["moonIllumination"] = moon["moonIllumination"];
    entry["moonrise"] = moon["moonrise"];
    entry["moonset"] = moon["moonset"];

    QVariantMap newData = m_solarData;
    newData[cityId] = entry;
    m_solarData = newData;

    emit solarDataChanged();
}
