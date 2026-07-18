#ifndef CITYDETAILSTORE_H
#define CITYDETAILSTORE_H

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QJsonObject>
#include <QJsonArray>

class WeatherAPI;

// CityDetailStore — C++ data layer for single-city detail view
// 城市详情数据层，聚合单个城市的实时天气、预报、空气质量、指数、预警、天文等全维度数据
class CityDetailStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap detail READ detail NOTIFY detailChanged)
    Q_PROPERTY(bool hasCity READ hasCity NOTIFY hasCityChanged)

public:
    explicit CityDetailStore(QObject* parent = nullptr);
    // setWeatherApi — Inject WeatherAPI dependency / 注入 WeatherAPI 依赖
    void setWeatherApi(WeatherAPI* api);

    // setCity — Select a city and trigger full data fetch / 选择城市并触发全量数据拉取
    Q_INVOKABLE void setCity(const QString& cityId, const QString& cityName,
                             const QString& lat, const QString& lon);

    QVariantMap detail() const { return m_detail; }  // All detail data for QML / 所有详情数据
    bool hasCity() const { return !m_cityId.isEmpty(); }  // Whether a city is selected / 是否已选择城市

signals:
    void detailChanged();
    void hasCityChanged();

private slots:
    // Response handlers / 各 API 回复处理
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
    // fetchAll — Request all data categories for current city / 请求当前城市的所有数据类别
    void fetchAll();
    // emitUpdated — Merge accumulated data and emit detailChanged / 合并累积数据并发出更新信号
    void emitUpdated();

    WeatherAPI* m_api = nullptr;    // Injected WeatherAPI / 注入的 API 实例
    QString m_cityId;               // Current city ID / 当前城市 ID
    QString m_cityName;             // Current city name / 当前城市名称
    QString m_lat;                  // Current city latitude / 当前城市纬度
    QString m_lon;                  // Current city longitude / 当前城市经度
    QVariantMap m_detail;           // Accumulated detail data / 累积的详情数据
};

#endif
