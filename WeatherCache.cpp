#include "WeatherCache.h"
#include <QCoreApplication>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDebug>

// WeatherCache constructor: initialize database / 构造函数：初始化数据库
WeatherCache::WeatherCache(QObject *parent)
    : QObject(parent)
{
    initDb();
}

// Destructor: close database / 析构函数：关闭数据库
WeatherCache::~WeatherCache()
{
    if (m_db.isOpen()) m_db.close();
}

// Initialize SQLite database for caching / 初始化 SQLite 缓存数据库
void WeatherCache::initDb()
{
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    // Portable: db sits next to the executable, delete to wipe / 绿色版：数据库与exe同目录，即删即走
    QString path = QCoreApplication::applicationDirPath() + "/weather_cache.db";
    m_db.setDatabaseName(path);

    if (!m_db.open()) {
        qWarning() << "WeatherCache: 无法打开数据库" << m_db.lastError().text();
        return;
    }

    // Create cache table if not exists / 创建缓存表
    QSqlQuery q(m_db);
    q.exec("CREATE TABLE IF NOT EXISTS cache ("
           "  k TEXT PRIMARY KEY,"
           "  data TEXT,"
           "  ts INTEGER"
           ")");
}

// Get cached value with TTL check / 获取缓存值并检查TTL过期
QString WeatherCache::get(const QString &key, int ttlSeconds)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT data, ts FROM cache WHERE k = ?");
    q.addBindValue(key);
    if (!q.exec() || !q.next()) return {};

    qint64 ts = q.value(1).toLongLong();
    qint64 now = QDateTime::currentSecsSinceEpoch();
    if (now - ts > ttlSeconds) {
        // Expired, delete entry / 过期，删除
        QSqlQuery del(m_db);
        del.prepare("DELETE FROM cache WHERE k = ?");
        del.addBindValue(key);
        del.exec();
        return {};
    }
    return q.value(0).toString();
}

// Set cached value with current timestamp / 设置缓存值并记录时间戳
void WeatherCache::set(const QString &key, const QString &json)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT OR REPLACE INTO cache (k, data, ts) VALUES (?, ?, ?)");
    q.addBindValue(key);
    q.addBindValue(json);
    q.addBindValue(QDateTime::currentSecsSinceEpoch());
    if (!q.exec())
        qWarning() << "WeatherCache: 写入失败" << q.lastError().text();
}

// Remove entries older than ttl / 移除超过TTL的过期条目
void WeatherCache::cleanExpired(int ttlSeconds)
{
    qint64 cutoff = QDateTime::currentSecsSinceEpoch() - ttlSeconds;
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM cache WHERE ts < ?");
    q.addBindValue(cutoff);
    q.exec();
}

// Clear all cached data / 清空所有缓存数据
void WeatherCache::clearAll()
{
    QSqlQuery q(m_db);
    q.exec("DELETE FROM cache");
}

// Save (upsert) a key-value pair / 保存（插入或替换）键值对
void WeatherCache::save(const QString &key, const QString &value)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT OR REPLACE INTO cache (k, data, ts) VALUES (?, ?, ?)");
    q.addBindValue(key);
    q.addBindValue(value);
    q.addBindValue(QDateTime::currentSecsSinceEpoch());
    q.exec();
}

// Load value by key (no TTL check) / 根据键加载值（无TTL检查）
QString WeatherCache::load(const QString &key)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT data FROM cache WHERE k = ?");
    q.addBindValue(key);
    if (!q.exec() || !q.next()) return {};
    return q.value(0).toString();
}
