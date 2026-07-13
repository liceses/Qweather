#ifndef FORECASTSTORE_H
#define FORECASTSTORE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonArray>

class WeatherAPI;

// C++ 数据层 —— 管理城市列表、触发预报API、预处理JSON为图表坐标
// 所有暴露给 QML 的数据均通过 Q_PROPERTY，保证信号驱动的可靠更新
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

    void setWeatherApi(WeatherAPI* api);

    QVariantList cities() const { return m_cities; }
    QString range() const { return m_range; }
    QString mode() const;
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
    void refreshAll();

    WeatherAPI* m_api = nullptr;
    QVariantList m_cities;
    QString m_range = "3d";
    QVariantMap m_chartData;
};

#endif
