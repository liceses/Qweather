#ifndef SOLAR_ASTRONOMY_STORE_H
#define SOLAR_ASTRONOMY_STORE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonObject>

class WeatherAPI;
class AppSettings;

// SolarAstronomyStore — C++ data layer for solar radiation & astronomy data
// 太阳辐射与天文数据层，合并太阳辐射、日出日落、月相数据后统一暴露给 QML
class SolarAstronomyStore : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantList cities READ cities WRITE setCities NOTIFY citiesChanged)
    Q_PROPERTY(QVariantMap solarData READ solarData NOTIFY solarDataChanged)
    // solarData: { "<cityId>": { ghi, dni, dhi, ghiUnit,
    //                             sunrise, sunset,
    //                             moonPhase, moonIcon, moonIllumination } }

public:
    explicit SolarAstronomyStore(QObject* parent = nullptr);

    // setWeatherApi / setAppSettings — Inject dependencies / 注入依赖
    void setWeatherApi(WeatherAPI* api);
    void setAppSettings(AppSettings* settings);

    QVariantList cities() const { return m_cities; }
    QVariantMap solarData() const { return m_solarData; }  // Final merged data for QML / 最终合并数据供 QML 使用

    void setCities(const QVariantList& cities);

signals:
    void citiesChanged();
    void solarDataChanged();

private slots:
    void onSolarRadiationReady(const QString& cityId, const QJsonObject& result);
    void onAstronomySunReady(const QString& cityId, const QJsonObject& result);
    void onAstronomyMoonReady(const QString& cityId, const QJsonObject& result);

private:
    // refreshAll — Fetch solar & astronomy for all cities / 刷新所有城市的太阳辐射与天文数据
    void refreshAll();
    // mergeAndEmit — Merge raw data for a city and emit update / 合并某城市的原始数据并发出更新信号
    void mergeAndEmit(const QString& cityId);

    WeatherAPI* m_api = nullptr;                // Injected WeatherAPI / 注入的 API 实例
    AppSettings* m_appSettings = nullptr;       // Injected AppSettings / 注入的应用设置
    QVariantList m_cities;                      // List of city configs / 城市配置列表
    QVariantMap m_solarData;                    // Final data exposed to QML / 最终数据，暴露给 QML
    QVariantMap m_solarRaw;                     // Intermediate accumulation / 中间累积数据
    //   { "<cityId>": { "solar":{...}, "sun":{...}, "moon":{...} } }
};

#endif
