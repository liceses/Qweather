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
    // 和风天气完整 68 码映射
    // struct: { particle, intensity, weatherVariant, cloudActive, cloudCoverage, cloudVariant, fogActive, fogIntensity, fogVariant, lightningActive }

    // === 白天 晴天类 100–104 ===
    m_dayProfiles[100] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false }; // 晴
    m_dayProfiles[101] = { "",     0.0f, 0, true,  0.30f, 1, false, 0.0f, 0, false }; // 多云
    m_dayProfiles[102] = { "",     0.0f, 0, true,  0.15f, 0, false, 0.0f, 0, false }; // 少云
    m_dayProfiles[103] = { "",     0.0f, 0, true,  0.20f, 0, false, 0.0f, 0, false }; // 晴间多云
    m_dayProfiles[104] = { "",     0.0f, 0, true,  0.90f, 2, false, 0.0f, 0, false }; // 阴

    // === 白天 雨类 300–399 ===
    m_dayProfiles[300] = { "rain", 0.4f, 0, true, 0.60f, 1, false, 0.0f, 0, false }; // 阵雨
    m_dayProfiles[301] = { "rain", 0.7f, 0, true, 0.80f, 2, false, 0.0f, 0, false }; // 强阵雨
    m_dayProfiles[302] = { "rain", 0.8f, 1, true, 0.90f, 2, false, 0.0f, 0, true  }; // 雷阵雨
    m_dayProfiles[303] = { "rain", 1.0f, 3, true, 1.00f, 2, false, 0.0f, 0, true  }; // 强雷阵雨
    m_dayProfiles[304] = { "rain", 0.8f, 2, true, 0.90f, 2, false, 0.0f, 0, true  }; // 雷阵雨伴有冰雹
    m_dayProfiles[305] = { "rain", 0.2f, 0, true, 0.50f, 1, false, 0.0f, 0, false }; // 小雨
    m_dayProfiles[306] = { "rain", 0.5f, 0, true, 0.70f, 1, false, 0.0f, 0, false }; // 中雨
    m_dayProfiles[307] = { "rain", 0.7f, 0, true, 0.80f, 2, false, 0.0f, 0, false }; // 大雨
    m_dayProfiles[308] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false }; // 极端降雨
    m_dayProfiles[309] = { "rain", 0.1f, 0, true, 0.40f, 1, false, 0.0f, 0, false }; // 毛毛雨
    m_dayProfiles[310] = { "rain", 0.8f, 0, true, 0.90f, 2, false, 0.0f, 0, false }; // 暴雨
    m_dayProfiles[311] = { "rain", 0.9f, 0, true, 1.00f, 2, false, 0.0f, 0, false }; // 大暴雨
    m_dayProfiles[312] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false }; // 特大暴雨
    m_dayProfiles[313] = { "rain", 0.4f, 2, true, 0.70f, 1, false, 0.0f, 0, false }; // 冻雨
    m_dayProfiles[314] = { "rain", 0.35f,0, true, 0.60f, 1, false, 0.0f, 0, false }; // 小到中雨
    m_dayProfiles[315] = { "rain", 0.6f, 0, true, 0.75f, 1, false, 0.0f, 0, false }; // 中到大雨
    m_dayProfiles[316] = { "rain", 0.8f, 0, true, 0.85f, 2, false, 0.0f, 0, false }; // 大到暴雨
    m_dayProfiles[317] = { "rain", 0.9f, 0, true, 0.95f, 2, false, 0.0f, 0, false }; // 暴雨到大暴雨
    m_dayProfiles[318] = { "rain", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false }; // 大暴雨到特大暴雨
    m_dayProfiles[399] = { "rain", 0.5f, 0, true, 0.60f, 1, false, 0.0f, 0, false }; // 雨(通用)

    // === 白天 雪类 400–499 ===
    m_dayProfiles[400] = { "snow", 0.2f, 0, true, 0.50f, 1, false, 0.0f, 0, false }; // 小雪
    m_dayProfiles[401] = { "snow", 0.5f, 0, true, 0.70f, 1, false, 0.0f, 0, false }; // 中雪
    m_dayProfiles[402] = { "snow", 0.8f, 0, true, 0.85f, 2, false, 0.0f, 0, false }; // 大雪
    m_dayProfiles[403] = { "snow", 1.0f, 0, true, 1.00f, 2, false, 0.0f, 0, false }; // 暴雪
    m_dayProfiles[404] = { "snow", 0.4f, 1, true, 0.60f, 1, false, 0.0f, 0, false }; // 雨夹雪
    m_dayProfiles[405] = { "snow", 0.5f, 1, true, 0.70f, 1, false, 0.0f, 0, false }; // 雨雪天气
    m_dayProfiles[406] = { "snow", 0.3f, 1, true, 0.50f, 1, false, 0.0f, 0, false }; // 阵雨夹雪
    m_dayProfiles[407] = { "snow", 0.3f, 0, true, 0.40f, 1, false, 0.0f, 0, false }; // 阵雪
    m_dayProfiles[408] = { "snow", 0.35f,0, true, 0.60f, 1, false, 0.0f, 0, false }; // 小到中雪
    m_dayProfiles[409] = { "snow", 0.65f,0, true, 0.75f, 1, false, 0.0f, 0, false }; // 中到大雪
    m_dayProfiles[410] = { "snow", 0.9f, 0, true, 0.90f, 2, false, 0.0f, 0, false }; // 大到暴雪
    m_dayProfiles[499] = { "snow", 0.5f, 0, true, 0.60f, 1, false, 0.0f, 0, false }; // 雪(通用)

    // === 白天 雾/霾/沙尘 500–515 ===
    m_dayProfiles[500] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.20f, 0, false }; // 薄雾
    m_dayProfiles[501] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.50f, 0, false }; // 雾
    m_dayProfiles[502] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.40f, 1, false }; // 霾
    m_dayProfiles[503] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.60f, 2, false }; // 扬沙
    m_dayProfiles[504] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.50f, 2, false }; // 浮尘
    m_dayProfiles[507] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.80f, 2, false }; // 沙尘暴
    m_dayProfiles[508] = { "",     0.0f, 0, false, 0.00f, 0, true, 1.00f, 2, false }; // 强沙尘暴
    m_dayProfiles[509] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.70f, 0, false }; // 浓雾
    m_dayProfiles[510] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.85f, 0, false }; // 强浓雾
    m_dayProfiles[511] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.50f, 1, false }; // 中度霾
    m_dayProfiles[512] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.70f, 1, false }; // 重度霾
    m_dayProfiles[513] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.90f, 1, false }; // 严重霾
    m_dayProfiles[514] = { "",     0.0f, 0, false, 0.00f, 0, true, 0.80f, 0, false }; // 大雾
    m_dayProfiles[515] = { "",     0.0f, 0, false, 0.00f, 0, true, 1.00f, 0, false }; // 特强浓雾

    // === 白天 极端/未知 ===
    m_dayProfiles[900] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false }; // 热
    m_dayProfiles[901] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false }; // 冷
    m_dayProfiles[999] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false }; // 未知

    // === 夜间覆盖 ===
    // 晴天类 150–153
    m_nightOverrides[150] = { "",     0.0f, 0, false, 0.00f, 0, false, 0.0f, 0, false }; // 晴(夜)
    m_nightOverrides[151] = { "",     0.0f, 0, true,  0.35f, 1, false, 0.0f, 0, false }; // 多云(夜)
    m_nightOverrides[152] = { "",     0.0f, 0, true,  0.85f, 2, false, 0.0f, 0, false }; // 阴(夜)
    m_nightOverrides[153] = { "",     0.0f, 0, true,  0.15f, 0, false, 0.0f, 0, false }; // 晴间多云(夜)
    // 夜间雨类 350–351
    m_nightOverrides[350] = { "rain", 0.4f, 0, true,  0.60f, 1, false, 0.0f, 0, false }; // 阵雨(夜)
    m_nightOverrides[351] = { "rain", 0.7f, 0, true,  0.80f, 2, false, 0.0f, 0, false }; // 强阵雨(夜)
    // 夜间雪类 456–457
    m_nightOverrides[456] = { "snow", 0.3f, 1, true,  0.50f, 1, false, 0.0f, 0, false }; // 阵雨夹雪(夜)
    m_nightOverrides[457] = { "snow", 0.3f, 0, true,  0.40f, 1, false, 0.0f, 0, false }; // 阵雪(夜)
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
