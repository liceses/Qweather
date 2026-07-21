#include "WeatherProfile.h"
#include <QJsonDocument>
#include <QFile>
#include <QDir>
#include <QDebug>

// WeatherProfileDB constructor: initialize default profiles / 构造函数：初始化默认天气描述档
WeatherProfileDB::WeatherProfileDB()
{
    initProfiles();
    qDebug() << "[WeatherProfileDB] initialized, day profiles:"
             << m_dayProfiles.size() << "night overrides:" << m_nightOverrides.size();
}

// ===== fromCode: look up profile by weather icon code / 根据天气图标编码查找描述档 =====

WeatherProfile WeatherProfileDB::fromCode(int iconCode) const
{
    if (m_dayProfiles.contains(iconCode))
        return m_dayProfiles[iconCode];
    if (m_nightOverrides.contains(iconCode))
        return m_nightOverrides[iconCode];
    // Fallback: clear sky / 兜底：晴天
    WeatherProfile sunny;
    sunny.cloudActive = false;
    return sunny;
}

// Debug dump all registered codes / 调试：输出所有注册编码
void WeatherProfileDB::dumpRegisteredCodes() const
{
    qDebug() << "[WeatherProfileDB] === Day Profiles ===";
    for (auto it = m_dayProfiles.cbegin(); it != m_dayProfiles.cend(); ++it) {
        const auto &p = it.value();
        qDebug() << "  code:" << it.key()
                 << "cloud:" << p.cloudCoverage
                 << "rain:" << (p.weatherParticle == "rain" ? p.intensity : 0)
                 << "snow:" << (p.weatherParticle == "snow" ? p.intensity : 0)
                 << "lightning:" << p.lightningActive;
    }
    qDebug() << "[WeatherProfileDB] === Night Overrides ===";
    for (auto it = m_nightOverrides.cbegin(); it != m_nightOverrides.cend(); ++it) {
        const auto &p = it.value();
        qDebug() << "  code:" << it.key()
                 << "cloud:" << p.cloudCoverage
                 << "rain:" << (p.weatherParticle == "rain" ? p.intensity : 0)
                 << "snow:" << (p.weatherParticle == "snow" ? p.intensity : 0)
                 << "lightning:" << p.lightningActive;
    }
}

// ===== initProfiles: built-in ~68 default weather mappings / 内置约68个默认天气映射 =====

void WeatherProfileDB::initProfiles()
{
    // Field order: { particle, intensity, weatherVariant, cloudActive, cloudCoverage, cloudVariant, fogActive, fogIntensity, fogVariant, lightningActive }

    // Clear / Sunny 晴 100–104
    m_dayProfiles[100] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false };
    m_dayProfiles[101] = { "",     0.0f, 0, true,  0.30f, 1, false, 0.0f, 0, false };
    m_dayProfiles[102] = { "",     0.0f, 0, true,  0.15f, 0, false, 0.0f, 0, false };
    m_dayProfiles[103] = { "",     0.0f, 0, true,  0.20f, 0, false, 0.0f, 0, false };
    m_dayProfiles[104] = { "",     0.0f, 0, true,  0.90f, 2, false, 0.0f, 0, false };
    // Rain 雨 300–399
    m_dayProfiles[300] = { "rain", 0.4f, 0, true, 0.60f, 1, false, 0.0f, 0, false };
    m_dayProfiles[301] = { "rain", 0.7f, 0, true, 0.80f, 2, false, 0.0f, 0, false };
    m_dayProfiles[302] = { "rain", 0.8f, 1, true, 0.90f, 2, false, 0.0f, 0, true  };
    m_dayProfiles[303] = { "rain", 1.0f, 3, true, 1.00f, 2, false, 0.0f, 0, true  };
    m_dayProfiles[304] = { "rain", 0.8f, 2, true, 0.90f, 2, false, 0.0f, 0, true  };
    m_dayProfiles[305] = { "rain", 0.2f, 0, true, 0.50f, 1, false, 0.0f, 0, false };
    m_dayProfiles[306] = { "rain", 0.5f, 0, true, 0.70f, 1, false, 0.0f, 0, false };
    m_dayProfiles[307] = { "rain", 0.7f, 0, true, 0.80f, 2, false, 0.0f, 0, false };
    m_dayProfiles[308] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_dayProfiles[309] = { "rain", 0.1f, 0, true, 0.40f, 1, false, 0.0f, 0, false };
    m_dayProfiles[310] = { "rain", 0.8f, 0, true, 0.90f, 2, false, 0.0f, 0, false };
    m_dayProfiles[311] = { "rain", 0.9f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_dayProfiles[312] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_dayProfiles[313] = { "rain", 0.4f, 2, true, 0.70f, 1, false, 0.0f, 0, false };
    m_dayProfiles[314] = { "rain", 0.35f,0, true, 0.60f, 1, false, 0.0f, 0, false };
    m_dayProfiles[315] = { "rain", 0.6f, 0, true, 0.75f, 1, false, 0.0f, 0, false };
    m_dayProfiles[316] = { "rain", 0.8f, 0, true, 0.85f, 2, false, 0.0f, 0, false };
    m_dayProfiles[317] = { "rain", 0.9f, 0, true, 0.95f, 2, false, 0.0f, 0, false };
    m_dayProfiles[318] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_dayProfiles[399] = { "rain", 0.5f, 0, true, 0.60f, 1, false, 0.0f, 0, false };
    // Snow 雪 400–499
    m_dayProfiles[400] = { "snow", 0.2f, 0, true, 0.50f, 1, false, 0.0f, 0, false };
    m_dayProfiles[401] = { "snow", 0.5f, 0, true, 0.70f, 1, false, 0.0f, 0, false };
    m_dayProfiles[402] = { "snow", 0.8f, 0, true, 0.85f, 2, false, 0.0f, 0, false };
    m_dayProfiles[403] = { "snow", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_dayProfiles[404] = { "snow", 0.4f, 1, true, 0.60f, 1, false, 0.0f, 0, false };
    m_dayProfiles[405] = { "snow", 0.5f, 1, true, 0.70f, 1, false, 0.0f, 0, false };
    m_dayProfiles[406] = { "snow", 0.3f, 1, true, 0.50f, 1, false, 0.0f, 0, false };
    m_dayProfiles[407] = { "snow", 0.3f, 0, true, 0.40f, 1, false, 0.0f, 0, false };
    m_dayProfiles[408] = { "snow", 0.35f,0, true, 0.60f, 1, false, 0.0f, 0, false };
    m_dayProfiles[409] = { "snow", 0.65f,0, true, 0.75f, 1, false, 0.0f, 0, false };
    m_dayProfiles[410] = { "snow", 0.9f, 0, true, 0.90f, 2, false, 0.0f, 0, false };
    // Haze / Fog / Dust 霾/雾/沙尘 500–515
    m_dayProfiles[500] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.20f, 0, false };
    m_dayProfiles[501] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.50f, 0, false };
    m_dayProfiles[502] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.40f, 1, false };
    m_dayProfiles[503] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.60f, 2, false };
    m_dayProfiles[504] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.50f, 2, false };
    m_dayProfiles[507] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.80f, 2, false };
    m_dayProfiles[508] = { "",     0.0f, 0, false, 0.00f, 0, true, 1.00f, 2, false };
    // Unknown / N/A 未知
    m_dayProfiles[999] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false };
    // Night overrides 夜晚覆盖 150–153
    m_nightOverrides[150] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false };
    m_nightOverrides[151] = { "",     0.0f, 0, true,  0.35f, 1, false, 0.0f, 0, false };
    m_nightOverrides[152] = { "",     0.0f, 0, true,  0.85f, 2, false, 0.0f, 0, false };
    m_nightOverrides[153] = { "",     0.0f, 0, true,  0.15f, 0, false, 0.0f, 0, false };
    m_nightOverrides[350] = { "rain", 0.4f, 0, true,  0.60f, 1, false, 0.0f, 0, false };
    m_nightOverrides[351] = { "rain", 0.7f, 0, true,  0.80f, 2, false, 0.0f, 0, false };
    m_nightOverrides[456] = { "snow", 0.3f, 1, true,  0.50f, 1, false, 0.0f, 0, false };
    m_nightOverrides[457] = { "snow", 0.3f, 0, true,  0.40f, 1, false, 0.0f, 0, false };
}

// ===== JSON serialization / JSON 序列化 =====

// Serialize WeatherProfile to JSON / 序列化 WeatherProfile 为 JSON
QJsonObject WeatherProfile::toJson() const {
    return {
        {"particle", weatherParticle},
        {"intensity", static_cast<double>(intensity)},
        {"weatherVariant", weatherVariant},
        {"cloudActive", cloudActive},
        {"cloudCoverage", static_cast<double>(cloudCoverage)},
        {"cloudVariant", cloudVariant},
        {"fogActive", fogActive},
        {"fogIntensity", static_cast<double>(fogIntensity)},
        {"fogVariant", fogVariant},
        {"lightningActive", lightningActive},
        {"exposureOffset", static_cast<double>(exposureOffset)}
    };
}

// Deserialize WeatherProfile from JSON / 从 JSON 反序列化 WeatherProfile
WeatherProfile WeatherProfile::fromJson(const QJsonObject &o) {
    WeatherProfile p;
    p.weatherParticle = o["particle"].toString();
    p.intensity = static_cast<float>(o["intensity"].toDouble());
    p.weatherVariant = o["weatherVariant"].toInt();
    p.cloudActive = o["cloudActive"].toBool();
    p.cloudCoverage = static_cast<float>(o["cloudCoverage"].toDouble());
    p.cloudVariant = o["cloudVariant"].toInt();
    p.fogActive = o["fogActive"].toBool();
    p.fogIntensity = static_cast<float>(o["fogIntensity"].toDouble());
    p.fogVariant = o["fogVariant"].toInt();
    p.lightningActive = o["lightningActive"].toBool();
    p.exposureOffset = static_cast<float>(o["exposureOffset"].toDouble());
    return p;
}

// Load profiles from JSON config file / 从 JSON 配置文件加载描述档
void WeatherProfileDB::loadFromFile(const QString &path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        qDebug() << "[WeatherProfileDB] no config file at" << path << "- using defaults";
        return;
    }
    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    QJsonObject root = doc.object();
    if (root.contains("day")) {
        QJsonObject days = root["day"].toObject();
        for (auto it = days.begin(); it != days.end(); ++it)
            m_dayProfiles[it.key().toInt()] = WeatherProfile::fromJson(it.value().toObject());
    }
    if (root.contains("night")) {
        QJsonObject nights = root["night"].toObject();
        for (auto it = nights.begin(); it != nights.end(); ++it)
            m_nightOverrides[it.key().toInt()] = WeatherProfile::fromJson(it.value().toObject());
    }
    qDebug() << "[WeatherProfileDB] loaded" << m_dayProfiles.size() << "day +"
             << m_nightOverrides.size() << "night from" << path;
}

// Save profiles to JSON config file / 将描述档保存到 JSON 配置文件
void WeatherProfileDB::saveToFile(const QString &path) const {
    QJsonObject root;
    QJsonObject days, nights;
    for (auto it = m_dayProfiles.begin(); it != m_dayProfiles.end(); ++it)
        days.insert(QString::number(it.key()), it.value().toJson());
    for (auto it = m_nightOverrides.begin(); it != m_nightOverrides.end(); ++it)
        nights.insert(QString::number(it.key()), it.value().toJson());
    root["day"] = days;
    root["night"] = nights;
    QFile f(path);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    qDebug() << "[WeatherProfileDB] saved" << m_dayProfiles.size() << "day +"
             << m_nightOverrides.size() << "night to" << path;
}
