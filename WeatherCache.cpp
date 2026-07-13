#include "WeatherCache.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDir>
#include <QDebug>

WeatherCache::WeatherCache(QObject *parent)
    : QObject(parent)
{
    initDb();
}

WeatherCache::~WeatherCache()
{
    if (m_db.isOpen()) m_db.close();
}

void WeatherCache::initDb()
{
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    QString path = QDir::homePath() + "/.qweather_cache.db";
    m_db.setDatabaseName(path);

    if (!m_db.open()) {
        qWarning() << "WeatherCache: 无法打开数据库" << m_db.lastError().text();
        return;
    }

    QSqlQuery q(m_db);
    q.exec("CREATE TABLE IF NOT EXISTS cache ("
           "  k TEXT PRIMARY KEY,"
           "  data TEXT,"
           "  ts INTEGER"
           ")");
}

QString WeatherCache::get(const QString &key, int ttlSeconds)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT data, ts FROM cache WHERE k = ?");
    q.addBindValue(key);
    if (!q.exec() || !q.next()) return {};

    qint64 ts = q.value(1).toLongLong();
    qint64 now = QDateTime::currentSecsSinceEpoch();
    if (now - ts > ttlSeconds) {
        // 过期，删掉
        QSqlQuery del(m_db);
        del.prepare("DELETE FROM cache WHERE k = ?");
        del.addBindValue(key);
        del.exec();
        return {};
    }
    return q.value(0).toString();
}

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

void WeatherCache::cleanExpired(int ttlSeconds)
{
    qint64 cutoff = QDateTime::currentSecsSinceEpoch() - ttlSeconds;
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM cache WHERE ts < ?");
    q.addBindValue(cutoff);
    q.exec();
}

void WeatherCache::clearAll()
{
    QSqlQuery q(m_db);
    q.exec("DELETE FROM cache");
}
