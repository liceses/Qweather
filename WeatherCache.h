#ifndef WEATHERCACHE_H
#define WEATHERCACHE_H

#include <QObject>
#include <QSqlDatabase>

class WeatherCache : public QObject {
    Q_OBJECT
public:
    explicit WeatherCache(QObject *parent = nullptr);
    ~WeatherCache();

    // 查缓存：命中返回 JSON，未命中返回空：
    Q_INVOKABLE QString get(const QString &key, int ttlSeconds);

    // 写缓存
    Q_INVOKABLE void set(const QString &key, const QString &json);

    // 清除过期数据
    Q_INVOKABLE void cleanExpired(int ttlSeconds);

    // 清除全部
    Q_INVOKABLE void clearAll();

private:
    void initDb();
    QSqlDatabase m_db;
};

#endif
