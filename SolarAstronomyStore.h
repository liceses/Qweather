#ifndef SOLAR_ASTRONOMY_STORE_H
#define SOLAR_ASTRONOMY_STORE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonObject>

class WeatherAPI;

class SolarAstronomyStore : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantList cities READ cities WRITE setCities NOTIFY citiesChanged)
    Q_PROPERTY(QVariantMap solarData READ solarData NOTIFY solarDataChanged)
    // solarData: { "<cityId>": { ghi, dni, dhi, ghiUnit,
    //                             sunrise, sunset,
    //                             moonPhase, moonIcon, moonIllumination } }

public:
    explicit SolarAstronomyStore(QObject* parent = nullptr);

    void setWeatherApi(WeatherAPI* api);

    QVariantList cities() const { return m_cities; }
    QVariantMap solarData() const { return m_solarData; }

    void setCities(const QVariantList& cities);

signals:
    void citiesChanged();
    void solarDataChanged();

private slots:
    void onSolarRadiationReady(const QString& cityId, const QJsonObject& result);
    void onAstronomySunReady(const QString& cityId, const QJsonObject& result);
    void onAstronomyMoonReady(const QString& cityId, const QJsonObject& result);

private:
    void refreshAll();
    void mergeAndEmit(const QString& cityId);

    WeatherAPI* m_api = nullptr;
    QVariantList m_cities;
    QVariantMap m_solarData;   // 最终数据，暴露给 QML
    QVariantMap m_solarRaw;    // 中间累积: { "<cityId>": { "solar":{...}, "sun":{...}, "moon":{...} } }
};

#endif
