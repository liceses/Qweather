#ifndef AIRQUALITYSTORE_H
#define AIRQUALITYSTORE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonObject>

class WeatherAPI;

class AirQualityStore : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantList cities READ cities WRITE setCities NOTIFY citiesChanged)
    Q_PROPERTY(QVariantMap airData READ airData NOTIFY airDataChanged)
    // airData: { "<cityId>": { aqi, aqiDisplay, level, category, primaryPollutant, color, pollutants[] } }

public:
    explicit AirQualityStore(QObject* parent = nullptr);

    void setWeatherApi(WeatherAPI* api);

    QVariantList cities() const { return m_cities; }
    QVariantMap airData() const { return m_airData; }

    void setCities(const QVariantList& cities);

signals:
    void citiesChanged();
    void airDataChanged();

private slots:
    void onAirCurrentReady(const QString& cityId, const QJsonObject& result);

private:
    void refreshAll();

    WeatherAPI* m_api = nullptr;
    QVariantList m_cities;
    QVariantMap m_airData;
};

#endif
