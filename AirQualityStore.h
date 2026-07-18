#ifndef AIRQUALITYSTORE_H
#define AIRQUALITYSTORE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonObject>

class WeatherAPI;

// AirQualityStore — C++ data layer for air quality data
// 空气质量数据层，管理城市列表与 AQI 数据，驱动 QML 空气质量卡片刷新
class AirQualityStore : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantList cities READ cities WRITE setCities NOTIFY citiesChanged)
    Q_PROPERTY(QVariantMap airData READ airData NOTIFY airDataChanged)
    // airData: { "<cityId>": { aqi, aqiDisplay, level, category, primaryPollutant, color, pollutants[] } }

public:
    explicit AirQualityStore(QObject* parent = nullptr);

    // setWeatherApi — Inject WeatherAPI dependency / 注入 WeatherAPI 依赖
    void setWeatherApi(WeatherAPI* api);

    QVariantList cities() const { return m_cities; }
    QVariantMap airData() const { return m_airData; }  // { "<cityId>": { aqi, level, category, ... } }

    void setCities(const QVariantList& cities);

signals:
    void citiesChanged();
    void airDataChanged();

private slots:
    void onAirCurrentReady(const QString& cityId, const QJsonObject& result);

private:
    // refreshAll — Fetch air quality for all cities / 刷新所有城市的空气质量数据
    void refreshAll();

    WeatherAPI* m_api = nullptr;    // Injected WeatherAPI / 注入的 API 实例
    QVariantList m_cities;          // List of city configs / 城市配置列表
    QVariantMap m_airData;          // AQI data map keyed by cityId / 按 cityId 索引的 AQI 数据
};

#endif
