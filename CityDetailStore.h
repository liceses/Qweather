#ifndef CITYDETAILSTORE_H
#define CITYDETAILSTORE_H

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QJsonObject>
#include <QJsonArray>

class WeatherAPI;

class CityDetailStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap detail READ detail NOTIFY detailChanged)
    Q_PROPERTY(bool hasCity READ hasCity NOTIFY hasCityChanged)

public:
    explicit CityDetailStore(QObject* parent = nullptr);
    void setWeatherApi(WeatherAPI* api);

    Q_INVOKABLE void setCity(const QString& cityId, const QString& cityName,
                             const QString& lat, const QString& lon);

    QVariantMap detail() const { return m_detail; }
    bool hasCity() const { return !m_cityId.isEmpty(); }

signals:
    void detailChanged();
    void hasCityChanged();

private slots:
    void onWeatherNowReady(const QJsonObject& obj);
    void onWeatherDailyReady(const QString& loc, const QJsonArray& arr);
    void onWeatherHourlyReady(const QString& loc, const QJsonArray& arr);
    void onAirCurrentReady(const QString& cityId, const QJsonObject& obj);
    void onIndicesReady(const QString& loc, const QJsonArray& arr);
    void onWarningNowReady(const QJsonObject& obj);
    void onAstronomySunReady(const QString& cityId, const QJsonObject& obj);
    void onAstronomyMoonReady(const QString& cityId, const QJsonObject& obj);
    void onSolarRadiationReady(const QString& cityId, const QJsonObject& obj);
    void onMinutelyPrecipReady(const QJsonObject& obj);

private:
    void fetchAll();
    void emitUpdated();

    WeatherAPI* m_api = nullptr;
    QString m_cityId;
    QString m_cityName;
    QString m_lat;
    QString m_lon;
    QVariantMap m_detail;
};

#endif
