#ifndef FORECASTSTORE_H
#define FORECASTSTORE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonArray>

class WeatherAPI;

// ForecastStore — C++ data layer for weather forecast charts
// 预报数据层，管理城市列表、触发预报 API、预处理 JSON 为图表坐标
// 所有暴露给 QML 的数据通过 Q_PROPERTY 保证信号驱动的可靠更新
class ForecastStore : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantList cities READ cities WRITE setCities NOTIFY citiesChanged)
    Q_PROPERTY(QString range READ range WRITE setRange NOTIFY rangeChanged)
    Q_PROPERTY(QString mode READ mode NOTIFY modeChanged)
    Q_PROPERTY(QVariantMap chartData READ chartData NOTIFY chartDataChanged)
    // chartData 结构:
    //   { "<cityId>_hourly": [{x:ts, y:temp}, ...],
    //     "<cityId>_daily":  [{x:ts, yMax, yMin}, ...],
    //     "<cityId>_info":   {icon, text, iconDay, textDay} }

public:
    explicit ForecastStore(QObject* parent = nullptr);

    // setWeatherApi — Inject WeatherAPI dependency / 注入 WeatherAPI 依赖
    void setWeatherApi(WeatherAPI* api);

    // Cities list & forecast range / 城市列表与预报天数范围
    QVariantList cities() const { return m_cities; }
    QString range() const { return m_range; }
    // mode — Derived property: "daily" for range≥7d, "hourly" otherwise / 派生属性：≥7天为 daily，否则 hourly
    QString mode() const;
    // chartData — Preprocessed chart coordinates { cityId_hourly: [], cityId_daily: [], cityId_info: {} }
    QVariantMap chartData() const { return m_chartData; }

    void setCities(const QVariantList& cities);
    void setRange(const QString& range);

signals:
    void citiesChanged();
    void rangeChanged();
    void modeChanged();
    void chartDataChanged();

private slots:
    void onWeatherDailyReady(const QString& loc, const QJsonArray& daily);
    void onWeatherHourlyReady(const QString& loc, const QJsonArray& hourly);

private:
    // refreshAll — Trigger API calls for all cities / 触发所有城市的 API 请求
    void refreshAll();

    WeatherAPI* m_api = nullptr;    // Injected WeatherAPI / 注入的 API 实例
    QVariantList m_cities;          // List of city configs / 城市配置列表
    QString m_range = "3d";         // Forecast range: "1d", "3d", "7d", "15d", "30d" / 预报天数范围
    QVariantMap m_chartData;        // Processed chart data for QML / 处理后的图表数据
};

#endif
