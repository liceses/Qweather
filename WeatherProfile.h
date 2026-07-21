#pragma once
#include <QString>
#include <QHash>
#include <QJsonObject>

// WeatherProfile — Rendering parameters for one weather condition code
// 单个天气码对应的渲染参数：粒子、云、雾、闪电等视觉层配置
struct WeatherProfile {
    QString weatherParticle;         // Particle system resource name / 粒子系统资源名
    float intensity = 0.0f;          // Weather effect intensity / 天气效果强度
    int weatherVariant = 0;          // Visual variant for weather layer / 天气层视觉子类型
    bool cloudActive = false;        // Whether cloud layer is active / 云层是否激活
    float cloudCoverage = 0.0f;      // Cloud coverage (0–1) / 云覆盖率
    int cloudVariant = 0;            // Visual variant for cloud layer / 云层视觉子类型
    bool fogActive = false;          // Whether fog layer is active / 雾层是否激活
    float fogIntensity = 0.0f;       // Fog density / 雾浓度
    int fogVariant = 0;              // Visual variant for fog layer / 雾层视觉子类型
    bool lightningActive = false;    // Whether lightning layer is active / 闪电层是否激活
    float exposureOffset = 0.0f;     // Exposure offset (-1~1) applied after S-curve modulation / 曝光偏移量，叠加到 S 曲线调制后的曝光

    // toJson / fromJson — Serialize / deserialize profile / 序列化/反序列化配置
    QJsonObject toJson() const;
    static WeatherProfile fromJson(const QJsonObject &o);
};

// WeatherProfileDB — Weather profile database indexed by icon code
// 天气配置数据库，按天气图标码索引
class WeatherProfileDB {
public:
    WeatherProfileDB();

    WeatherProfile fromCode(int iconCode) const;
    void dumpRegisteredCodes() const;

    void loadFromFile(const QString &path);
    void saveToFile(const QString &path) const;

    const QHash<int, WeatherProfile> &profiles() const { return m_profiles; }
    void setProfile(int code, const WeatherProfile &p) { m_profiles[code] = p; }

private:
    QHash<int, WeatherProfile> m_profiles;
    void initProfiles();
};
