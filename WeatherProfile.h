#pragma once
#include <QString>
#include <QHash>

// WeatherProfile: 天气码 → 物理状态
// 注：当前为骨架实现（debug 阶段），完整 68 码映射推迟实现
struct WeatherProfile {
    QString weatherParticle;  // "" | "rain" | "snow"
    float intensity = 0.0f;
    int weatherVariant = 0;   // rain:0普通/1雷暴/2雹/3雷暴+雹  snow:0纯/1雨夹雪
    bool cloudActive = false;
    float cloudCoverage = 0.0f;
    int cloudVariant = 0;     // 0少云/1多云/2阴
    bool fogActive = false;
    float fogIntensity = 0.0f;
    int fogVariant = 0;       // 0雾/1霾/2沙尘
    bool lightningActive = false;
};

class WeatherProfileDB {
public:
    WeatherProfileDB();

    // 根据天气码查询 Profile
    WeatherProfile fromCode(int iconCode, bool isDay) const;

    // 验证: 输出所有已注册的映射
    void dumpRegisteredCodes() const;

private:
    QHash<int, WeatherProfile> m_dayProfiles;
    QHash<int, WeatherProfile> m_nightOverrides;

    void initProfiles();         // 初始化全部 68 码映射

    static float rainIntensity(int code);
    static float snowIntensity(int code);
    static float fogIntensity(int code);
    static int rainVariant(int code);
    static int snowVariant(int code);
    static int fogVariant(int code);
};
