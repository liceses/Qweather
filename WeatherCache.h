#ifndef WEATHERCACHE_H
#define WEATHERCACHE_H

#include <QObject>
#include <QSqlDatabase>

// WeatherCache — SQLite key-value cache with TTL expiry
// SQLite 缓存，键值对存储，自带 TTL 过期自动清理机制
// 数据库文件：~/.qweather_cache.db；Q_INVOKABLE 方法可在 QML 中直接调用
class WeatherCache : public QObject {
    Q_OBJECT
public:
    explicit WeatherCache(QObject *parent = nullptr);
    ~WeatherCache();

    // get — Lookup cached JSON; returns empty string on miss / 查询缓存，命中返回 JSON，未命中返回空
    Q_INVOKABLE QString get(const QString &key, int ttlSeconds);

    // set — Write JSON to cache / 写入缓存
    Q_INVOKABLE void set(const QString &key, const QString &json);

    // cleanExpired — Remove entries older than ttlSeconds / 清除过期数据
    Q_INVOKABLE void cleanExpired(int ttlSeconds);

    // clearAll — Wipe entire cache / 清除全部缓存
    Q_INVOKABLE void clearAll();

    // Persistent storage (no TTL, for favorites/history/settings) / 持久化存储（无 TTL，用于收藏/历史/设置）
    Q_INVOKABLE void save(const QString &key, const QString &value);
    Q_INVOKABLE QString load(const QString &key);

private:
    void initDb();              // Initialize SQLite database / 初始化 SQLite 数据库
    QSqlDatabase m_db;          // SQLite database connection / SQLite 数据库连接
};

#endif
