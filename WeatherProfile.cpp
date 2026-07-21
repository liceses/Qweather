#include "WeatherProfile.h"
#include <QJsonDocument>
#include <QFile>
#include <QDir>
#include <QDebug>

// WeatherProfileDB constructor: initialize default profiles / 构造函数：初始化默认天气配置
WeatherProfileDB::WeatherProfileDB()
{
    initProfiles();
    qDebug() << "[WeatherProfileDB] initialized" << m_profiles.size() << "profiles";
}

// ===== fromCode: look up profile by weather icon code / 根据天气图标码查找配置 =====

WeatherProfile WeatherProfileDB::fromCode(int iconCode) const
{
    if (m_profiles.contains(iconCode))
        return m_profiles[iconCode];
    WeatherProfile sunny;
    sunny.cloudActive = false;
    return sunny;
}

// Debug dump all registered codes / 调试：输出所有已注册码
void WeatherProfileDB::dumpRegisteredCodes() const
{
    qDebug() << "[WeatherProfileDB] === Profiles ===";
    for (auto it = m_profiles.cbegin(); it != m_profiles.cend(); ++it) {
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
    m_profiles[100] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false };
    m_profiles[101] = { "",     0.0f, 0, true,  0.30f, 1, false, 0.0f, 0, false };
    m_profiles[102] = { "",     0.0f, 0, true,  0.15f, 0, false, 0.0f, 0, false };
    m_profiles[103] = { "",     0.0f, 0, true,  0.20f, 0, false, 0.0f, 0, false };
    m_profiles[104] = { "",     0.0f, 0, true,  0.90f, 2, false, 0.0f, 0, false };
    // Night variants 夜间变体 150–153
    m_profiles[150] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false };
    m_profiles[151] = { "",     0.0f, 0, true,  0.35f, 1, false, 0.0f, 0, false };
    m_profiles[152] = { "",     0.0f, 0, true,  0.85f, 2, false, 0.0f, 0, false };
    m_profiles[153] = { "",     0.0f, 0, true,  0.15f, 0, false, 0.0f, 0, false };
    // Rain 雨 300–399
    m_profiles[300] = { "rain", 0.4f, 0, true, 0.60f, 1, false, 0.0f, 0, false };
    m_profiles[301] = { "rain", 0.7f, 0, true, 0.80f, 2, false, 0.0f, 0, false };
    m_profiles[302] = { "rain", 0.8f, 1, true, 0.90f, 2, false, 0.0f, 0, true  };
    m_profiles[303] = { "rain", 1.0f, 3, true, 1.00f, 2, false, 0.0f, 0, true  };
    m_profiles[304] = { "rain", 0.8f, 2, true, 0.90f, 2, false, 0.0f, 0, true  };
    m_profiles[305] = { "rain", 0.2f, 0, true, 0.50f, 1, false, 0.0f, 0, false };
    m_profiles[306] = { "rain", 0.5f, 0, true, 0.70f, 1, false, 0.0f, 0, false };
    m_profiles[307] = { "rain", 0.7f, 0, true, 0.80f, 2, false, 0.0f, 0, false };
    m_profiles[308] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_profiles[309] = { "rain", 0.1f, 0, true, 0.40f, 1, false, 0.0f, 0, false };
    m_profiles[310] = { "rain", 0.8f, 0, true, 0.90f, 2, false, 0.0f, 0, false };
    m_profiles[311] = { "rain", 0.9f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_profiles[312] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_profiles[313] = { "rain", 0.4f, 2, true, 0.70f, 1, false, 0.0f, 0, false };
    m_profiles[314] = { "rain", 0.35f,0, true, 0.60f, 1, false, 0.0f, 0, false };
    m_profiles[315] = { "rain", 0.6f, 0, true, 0.75f, 1, false, 0.0f, 0, false };
    m_profiles[316] = { "rain", 0.8f, 0, true, 0.85f, 2, false, 0.0f, 0, false };
    m_profiles[317] = { "rain", 0.9f, 0, true, 0.95f, 2, false, 0.0f, 0, false };
    m_profiles[318] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_profiles[350] = { "rain", 0.4f, 0, true,  0.60f, 1, false, 0.0f, 0, false };
    m_profiles[351] = { "rain", 0.7f, 0, true,  0.80f, 2, false, 0.0f, 0, false };
    m_profiles[399] = { "rain", 0.5f, 0, true, 0.60f, 1, false, 0.0f, 0, false };
    // Snow 雪 400–499
    m_profiles[400] = { "snow", 0.2f, 0, true, 0.50f, 1, false, 0.0f, 0, false };
    m_profiles[401] = { "snow", 0.5f, 0, true, 0.70f, 1, false, 0.0f, 0, false };
    m_profiles[402] = { "snow", 0.8f, 0, true, 0.85f, 2, false, 0.0f, 0, false };
    m_profiles[403] = { "snow", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false };
    m_profiles[404] = { "snow", 0.4f, 1, true, 0.60f, 1, false, 0.0f, 0, false };
    m_profiles[405] = { "snow", 0.5f, 1, true, 0.70f, 1, false, 0.0f, 0, false };
    m_profiles[406] = { "snow", 0.3f, 1, true, 0.50f, 1, false, 0.0f, 0, false };
    m_profiles[407] = { "snow", 0.3f, 0, true, 0.40f, 1, false, 0.0f, 0, false };
    m_profiles[408] = { "snow", 0.35f,0, true, 0.60f, 1, false, 0.0f, 0, false };
    m_profiles[409] = { "snow", 0.65f,0, true, 0.75f, 1, false, 0.0f, 0, false };
    m_profiles[410] = { "snow", 0.9f, 0, true, 0.90f, 2, false, 0.0f, 0, false };
    m_profiles[456] = { "snow", 0.3f, 1, true,  0.50f, 1, false, 0.0f, 0, false };
    m_profiles[457] = { "snow", 0.3f, 0, true,  0.40f, 1, false, 0.0f, 0, false };
    // Haze / Fog / Dust 霾/雾/沙尘 500–515
    m_profiles[500] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.20f, 0, false };
    m_profiles[501] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.50f, 0, false };
    m_profiles[502] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.40f, 1, false };
    m_profiles[503] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.60f, 2, false };
    m_profiles[504] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.50f, 2, false };
    m_profiles[507] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.80f, 2, false };
    m_profiles[508] = { "",     0.0f, 0, false, 0.00f, 0, true, 1.00f, 2, false };
    // Unknown / N/A 未知
    m_profiles[999] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false };
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

// Load profiles from JSON config file / 从 JSON 配置文件加载配置
void WeatherProfileDB::loadFromFile(const QString &path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        qDebug() << "[WeatherProfileDB] no config file at" << path << "- using defaults";
        return;
    }
    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    QJsonObject root = doc.object().value("profiles").toObject();
    for (auto it = root.begin(); it != root.end(); ++it)
        m_profiles[it.key().toInt()] = WeatherProfile::fromJson(it.value().toObject());
    qDebug() << "[WeatherProfileDB] loaded" << m_profiles.size() << "profiles from" << path;
}

// Save profiles to JSON config file / 将配置保存到 JSON 配置文件
void WeatherProfileDB::saveToFile(const QString &path) const {
    QJsonObject profiles;
    for (auto it = m_profiles.begin(); it != m_profiles.end(); ++it)
        profiles.insert(QString::number(it.key()), it.value().toJson());
    QJsonObject root;
    root["profiles"] = profiles;
    QFile f(path);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    qDebug() << "[WeatherProfileDB] saved" << m_profiles.size() << "profiles to" << path;
}
