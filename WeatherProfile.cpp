#include "WeatherProfile.h"
#include <QDebug>
#include <QtMath>

WeatherProfileDB::WeatherProfileDB()
{
    // 初始化映射表
    initProfiles();
    qDebug() << "[WeatherProfileDB] initialized, day profiles:" << m_dayProfiles.size()
             << "night overrides:" << m_nightOverrides.size();
}

WeatherProfile WeatherProfileDB::fromCode(int iconCode, bool isDay) const
{
    // 夜间覆盖优先
    if (!isDay && m_nightOverrides.contains(iconCode)) {
        return m_nightOverrides.value(iconCode);
    }
    // 白天查表
    if (m_dayProfiles.contains(iconCode)) {
        return m_dayProfiles.value(iconCode);
    }
    // 未知码 → 返回晴天默认
    qDebug() << "[WeatherProfileDB] unknown code:" << iconCode << "isDay:" << isDay << "→ falling back to sunny";
    WeatherProfile sunny;
    sunny.cloudActive = false;
    return sunny;
}

void WeatherProfileDB::dumpRegisteredCodes() const
{
    qDebug() << "[WeatherProfileDB] === Day Profiles ===";
    for (auto it = m_dayProfiles.cbegin(); it != m_dayProfiles.cend(); ++it) {
        const auto &p = it.value();
        qDebug() << "  code:" << it.key()
                 << "cloud:" << p.cloudCoverage
                 << "rain:" << (p.weatherParticle == "rain" ? p.intensity : 0)
                 << "snow:" << (p.weatherParticle == "snow" ? p.intensity : 0)
                 << "fog:" << p.fogIntensity
                 << "lightning:" << p.lightningActive;
    }
    qDebug() << "[WeatherProfileDB] === Night Overrides ===";
    for (auto it = m_nightOverrides.cbegin(); it != m_nightOverrides.cend(); ++it) {
        qDebug() << "  code:" << it.key()
                 << "cloud:" << it.value().cloudCoverage;
    }
}

void WeatherProfileDB::initProfiles()
{
    // TODO: 完整 68 码映射（推迟实现）
    // 目前只注册少数典型码用于 debug
    // 和风天气 icon code 范围: 100~104(晴/多云/阴), 300~304(雨), 400~404(雪), 500~504(雾/霾)

    // === 白天 ===
    // 100: 晴
    m_dayProfiles[100] = { "", 0, 0, false, 0.0f, 0, false, 0.0f, 0, false };
    // 101: 多云
    m_dayProfiles[101] = { "", 0, 0, true, 0.3f, 1, false, 0.0f, 0, false };
    // 102: 少云 (和风用 102 表示少云)
    m_dayProfiles[102] = { "", 0, 0, true, 0.15f, 0, false, 0.0f, 0, false };
    // 103: 晴间多云
    m_dayProfiles[103] = { "", 0, 0, true, 0.2f, 0, false, 0.0f, 0, false };
    // 104: 阴
    m_dayProfiles[104] = { "", 0, 0, true, 0.9f, 2, false, 0.0f, 0, false };
    // 300: 阵雨
    m_dayProfiles[300] = { "rain", 0.4f, 0, true, 0.6f, 1, false, 0.0f, 0, false };
    // 301: 强阵雨
    m_dayProfiles[301] = { "rain", 0.7f, 0, true, 0.8f, 2, false, 0.0f, 0, false };
    // 302: 雷暴
    m_dayProfiles[302] = { "rain", 0.8f, 1, true, 0.9f, 2, false, 0.0f, 0, true };
    // 303: 强雷暴
    m_dayProfiles[303] = { "rain", 1.0f, 3, true, 1.0f, 2, false, 0.0f, 0, true };
    // 400: 雪
    m_dayProfiles[400] = { "snow", 0.4f, 0, true, 0.7f, 2, false, 0.0f, 0, false };
    // 401: 阵雪
    m_dayProfiles[401] = { "snow", 0.3f, 0, true, 0.5f, 1, false, 0.0f, 0, false };
    // 402: 大雪
    m_dayProfiles[402] = { "snow", 0.8f, 0, true, 0.9f, 2, false, 0.0f, 0, false };
    // 500: 薄雾
    m_dayProfiles[500] = { "", 0, 0, false, 0.0f, 0, true, 0.3f, 0, false };
    // 501: 雾
    m_dayProfiles[501] = { "", 0, 0, false, 0.0f, 0, true, 0.6f, 0, false };
    // 502: 霾
    m_dayProfiles[502] = { "", 0, 0, false, 0.0f, 0, true, 0.5f, 1, false };
    // 503: 沙尘
    m_dayProfiles[503] = { "", 0, 0, false, 0.0f, 0, true, 0.7f, 2, false };

    // === 夜间覆盖 ===
    // 150: 晴(夜)
    m_nightOverrides[150] = { "", 0, 0, false, 0.0f, 0, false, 0.0f, 0, false };
    // 151: 多云(夜)
    m_nightOverrides[151] = { "", 0, 0, true, 0.35f, 1, false, 0.0f, 0, false };
    // 152: 阴(夜)
    m_nightOverrides[152] = { "", 0, 0, true, 0.85f, 2, false, 0.0f, 0, false };
    // 153: 晴间多云(夜)
    m_nightOverrides[153] = { "", 0, 0, true, 0.15f, 0, false, 0.0f, 0, false };
}

// ===== 静态辅助 =====
float WeatherProfileDB::rainIntensity(int code)
{
    Q_UNUSED(code);
    // TODO: 根据 code 精确映射
    return 0.5f;
}

float WeatherProfileDB::snowIntensity(int code)
{
    Q_UNUSED(code);
    return 0.5f;
}

float WeatherProfileDB::fogIntensity(int code)
{
    Q_UNUSED(code);
    return 0.5f;
}

int WeatherProfileDB::rainVariant(int code)
{
    Q_UNUSED(code);
    return 0;
}

int WeatherProfileDB::snowVariant(int code)
{
    Q_UNUSED(code);
    return 0;
}

int WeatherProfileDB::fogVariant(int code)
{
    Q_UNUSED(code);
    return 0;
}
