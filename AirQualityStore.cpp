#include "AirQualityStore.h"
#include "weatherApi.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

// AirQualityStore — constructor / 构造函数
AirQualityStore::AirQualityStore(QObject* parent) : QObject(parent) {}

// setWeatherApi — inject API & connect air signal / 注入 API 并连接空气质量信号
void AirQualityStore::setWeatherApi(WeatherAPI* api) {
    if (m_api)
        disconnect(m_api, nullptr, this, nullptr);
    m_api = api;
    if (m_api) {
        connect(m_api, &WeatherAPI::airCurrentReady,
                this, &AirQualityStore::onAirCurrentReady);
    }
}

// setCities — set tracked cities & refresh / 设置关注城市并刷新
void AirQualityStore::setCities(const QVariantList& cities) {
    m_cities = cities;
    qDebug() << "[AirQualityStore] setCities count:" << m_cities.size();
    emit citiesChanged();
    refreshAll();
}

// refreshAll — fetch air quality for each city / 刷新所有城市空气质量
void AirQualityStore::refreshAll() {
    if (!m_api || m_cities.isEmpty()) {
        qDebug() << "[AirQualityStore] refreshAll skip: api=" << (m_api != nullptr) << "cities=" << m_cities.size();
        return;
    }
    int count = qMin(m_cities.size(), 4);
    qDebug() << "[AirQualityStore] refreshAll count=" << count;
    for (int i = 0; i < count; ++i) {
        QVariantMap city = m_cities[i].toMap();
        QString id = city["id"].toString();
        QString lat = city["lat"].toString();
        QString lon = city["lon"].toString();
        QString name = city["name"].toString();
        qDebug() << "[AirQualityStore]   requesting air for" << name << id << lat << lon;
        if (!lat.isEmpty() && !lon.isEmpty())
            m_api->airCurrent(lat, lon, id);
    }
}

// onAirCurrentReady — parse AQI response / 解析空气质量响应
void AirQualityStore::onAirCurrentReady(const QString& cityId, const QJsonObject& result) {
    // 解析 indexes 数组：优先选择 us-epa 标准
    QJsonArray indexes = result["indexes"].toArray();
    QJsonObject bestIndex;
    for (const QJsonValue& v : indexes) {
        QJsonObject idx = v.toObject();
        if (idx["code"].toString() == "us-epa") {
            bestIndex = idx;
            break;
        }
    }
    if (bestIndex.isEmpty() && !indexes.isEmpty())
        bestIndex = indexes.first().toObject();

    // 解析首要污染物
    QString primaryPollutant;
    QJsonObject pp = bestIndex["primaryPollutant"].toObject();
    if (!pp.isEmpty())
        primaryPollutant = pp["name"].toString();

    // 解析颜色
    QJsonObject colorObj = bestIndex["color"].toObject();
    QString colorHex = "#00e400";
    if (!colorObj.isEmpty()) {
        int r = colorObj["red"].toInt();
        int g = colorObj["green"].toInt();
        int b = colorObj["blue"].toInt();
        colorHex = QString("#%1%2%3")
            .arg(r, 2, 16, QLatin1Char('0'))
            .arg(g, 2, 16, QLatin1Char('0'))
            .arg(b, 2, 16, QLatin1Char('0'));
    }

    // 解析污染物列表
    QVariantList pollutants;
    QJsonArray pollArr = result["pollutants"].toArray();
    for (const QJsonValue& v : pollArr) {
        QJsonObject p = v.toObject();
        QJsonObject conc = p["concentration"].toObject();
        QVariantMap pm;
        pm["name"] = p["name"].toString();
        pm["value"] = conc["value"].toDouble();
        pm["unit"] = conc["unit"].toString();
        pollutants.append(pm);
    }

    // 组装 airData
    QVariantMap entry;
    entry["aqi"] = bestIndex["aqiDisplay"].toString();
    entry["level"] = bestIndex["level"].toString();
    entry["category"] = bestIndex["category"].toString();
    entry["primaryPollutant"] = primaryPollutant;
    entry["color"] = colorHex;
    entry["pollutants"] = pollutants;

    QVariantMap newData = m_airData;
    newData[cityId] = entry;
    m_airData = newData;

    qDebug() << "[AirQualityStore] airReady" << cityId << "AQI:" << entry["aqi"].toString() << entry["category"].toString();
    emit airDataChanged();
}
