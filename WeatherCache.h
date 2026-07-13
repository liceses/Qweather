#ifndef WEATHERCACHE_H
#define WEATHERCACHE_H

#include <QObject>
#include <QSqlDatabase>

// SQLite 缓存 —— 键值对存储，自带 TTL 过期机制
// 数据库文件：~/.qweather_cache.db
// Q_INVOKABLE 方法可在 QML 中直接调用（如 cleanExpired / clearAll）
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
