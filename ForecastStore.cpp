#include "ForecastStore.h"
#include "weatherApi.h"
#include <QJsonObject>
#include <QDateTime>
#include <QDebug>

// ForecastStore — constructor / 构造函数
ForecastStore::ForecastStore(QObject* parent) : QObject(parent) {}

// setWeatherApi — inject API object & connect signals / 注入 API 对象并连接信号
void ForecastStore::setWeatherApi(WeatherAPI* api) {
    if (m_api)
        disconnect(m_api, nullptr, this, nullptr);
    m_api = api;
    if (m_api) {
        connect(m_api, &WeatherAPI::weatherDailyReady,
                this, &ForecastStore::onWeatherDailyReady);
        connect(m_api, &WeatherAPI::weatherHourlyReady,
                this, &ForecastStore::onWeatherHourlyReady);
    }
}

// mode — "hourly" if range contains 'h', else "daily" / 判断预报模式
QString ForecastStore::mode() const {
    return m_range.contains('h') ? "hourly" : "daily";
}

// setCities — set tracked cities & refresh / 设置关注城市并刷新
void ForecastStore::setCities(const QVariantList& cities) {
    m_cities = cities;
    qDebug() << "[ForecastStore] setCities count:" << m_cities.size();
    emit citiesChanged();
    refreshAll();
}

// setRange — set forecast range (e.g. "3d", "24h") / 设置预报天数/小时数
void ForecastStore::setRange(const QString& range) {
    if (m_range == range) return;
    m_range = range;
    qDebug() << "[ForecastStore] setRange:" << range;
    emit rangeChanged();
    emit modeChanged();
    refreshAll();
}

// refreshAll — fetch forecast for each tracked city / 刷新所有城市预报
void ForecastStore::refreshAll() {
    if (!m_api || m_cities.isEmpty()) {
        qDebug() << "[ForecastStore] refreshAll skip: api=" << (m_api != nullptr) << "cities=" << m_cities.size();
        return;
    }
    bool isHourly = m_range.contains('h');
    int count = qMin(m_cities.size(), 4);   //todo:功能拓展,显示城市数量可设置,而非硬编码上限4个
    qDebug() << "[ForecastStore] refreshAll mode=" << (isHourly ? "hourly" : "daily") << "range=" << m_range << "count=" << count;
    for (int i = 0; i < count; ++i) {
        QString id = m_cities[i].toMap()["id"].toString();
        QString name = m_cities[i].toMap()["name"].toString();
        qDebug() << "[ForecastStore]   requesting" << m_range << "for" << name << id;
        if (isHourly)
            m_api->weatherHourly(m_range, id);
        else
            m_api->weatherDaily(m_range, id);
    }
}

// ---- 数据预处理：JSON → QVariantList 图表坐标 / Data transform for chart ----

// onWeatherDailyReady — convert daily JSON to chart points / 将逐天预报转为图表坐标
void ForecastStore::onWeatherDailyReady(const QString& loc, const QJsonArray& daily) {
    QVariantList points;
    QString iconDay, textDay;

    for (const QJsonValue& val : daily) {
        QJsonObject obj = val.toObject();
        QVariantMap pt;
        QDateTime dt = QDateTime::fromString(obj["fxDate"].toString(), "yyyy-MM-dd");
        pt["x"]    = dt.isValid() ? dt.toMSecsSinceEpoch() : 0LL;
        pt["yMax"] = obj["tempMax"].toString().toDouble();
        pt["yMin"] = obj["tempMin"].toString().toDouble();
        points.append(pt);

        if (iconDay.isEmpty()) {
            iconDay = obj["iconDay"].toString();
            textDay = obj["textDay"].toString();
        }
    }

    // 写时复制：创建新 map 确保 QML 检测到引用变化
    QVariantMap newData = m_chartData;
    newData[loc + "_daily"] = points;

    QVariantMap info = newData[loc + "_info"].toMap();
    info["iconDay"] = iconDay;
    info["textDay"] = textDay;
    newData[loc + "_info"] = info;

    m_chartData = newData;
    qDebug() << "[ForecastStore] dailyReady" << loc << "points:" << points.size() << textDay;
    emit chartDataChanged();
}

// onWeatherHourlyReady — convert hourly JSON to chart points / 将逐小时预报转为图表坐标
void ForecastStore::onWeatherHourlyReady(const QString& loc, const QJsonArray& hourly) {
    QVariantList points;
    QString icon, text;

    for (const QJsonValue& val : hourly) {
        QJsonObject obj = val.toObject();
        QVariantMap pt;
        QDateTime dt = QDateTime::fromString(obj["fxTime"].toString(), Qt::ISODate);
        pt["x"] = dt.isValid() ? dt.toMSecsSinceEpoch() : 0LL;
        pt["y"] = obj["temp"].toString().toDouble();
        points.append(pt);

        if (icon.isEmpty()) {
            icon = obj["icon"].toString();
            text = obj["text"].toString();
        }
    }

    QVariantMap newData = m_chartData;
    newData[loc + "_hourly"] = points;

    QVariantMap info = newData[loc + "_info"].toMap();
    info["icon"] = icon;
    info["text"] = text;
    newData[loc + "_info"] = info;

    m_chartData = newData;
    qDebug() << "[ForecastStore] hourlyReady" << loc << "points:" << points.size() << text;
    emit chartDataChanged();
}
