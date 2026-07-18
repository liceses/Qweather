#pragma once
#include <QObject>
#include <QDateTime>
#include <QtMath>

// AstronomyModel — Sun & moon position calculator
// 太阳/月亮位置计算模型，基于简化天文公式驱动天空渲染
class AstronomyModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(float solarAltitude  READ solarAltitude  NOTIFY updated)
    Q_PROPERTY(float solarAzimuth   READ solarAzimuth   NOTIFY updated)
    Q_PROPERTY(float moonAltitude   READ moonAltitude   NOTIFY updated)
    Q_PROPERTY(float moonAzimuth    READ moonAzimuth    NOTIFY updated)
    Q_PROPERTY(float moonPhase      READ moonPhase      NOTIFY updated)
    Q_PROPERTY(float moonIllum      READ moonIllum      NOTIFY updated)

public:
    explicit AstronomyModel(QObject *parent = nullptr);

    // Input setters / 输入设置
    void setLocation(float lat, float lon);                          // Set geographic coordinates / 设置地理坐标
    void setSunTimes(const QString &sunrise, const QString &sunset); // Set sunrise/sunset from API / 从 API 设置日出日落时间
    void setMoonData(int phaseIcon, float illumination);             // Set moon phase & illumination / 设置月相与月照率
    void update(qint64 nowMsecs);                                    // Update from real time / 根据实时时间更新
    void updateByMinute(int minuteOfDay);                            // Update from debug minute / 调试：根据分钟数更新

    // Read-only output getters / 只读输出访问器
    float solarAltitude()  const { return m_solarAltitude; }
    float solarAzimuth()   const { return m_solarAzimuth; }
    float moonAltitude()   const { return m_moonAltitude; }
    float moonAzimuth()    const { return m_moonAzimuth; }
    float moonPhase()      const { return m_moonPhase; }
    float moonIllum()      const { return m_moonIllum; }

    // Derived values / 派生值
    float sunProgress() const;       // 0=dawn, 0.5=noon, 1=dusk / 0=黎明, 0.5=正午, 1=黄昏
    float dayProgress() const;       // Unclamped, -0.5~1.5 range / 无 clamp，-0.5~1.5 范围
    bool isNight() const;            // Whether current time is night / 当前是否为夜晚
    int sunriseMin() const { return m_sunriseMin; }  // Sunrise minute of day / 日出分钟
    int sunsetMin()  const { return m_sunsetMin; }   // Sunset minute of day / 日落分钟
    int currentMin() const { return m_currentMin; }  // Current minute of day / 当前分钟
    int dayOfYear()  const { return m_dayOfYear; }   // Day of year (1–366) / 年积日

signals:
    void updated();

private:
    float m_lat = 39.9f, m_lon = 116.4f;       // Default: Beijing coordinates / 默认：北京 (39.9°N, 116.4°E)
    int m_dayOfYear = 196;       // Default: July 15 / 默认 7 月 15 日 (dayOfYear=196)
    int m_lonOffset = 0;         // Longitude timezone offset in minutes / 经度时区偏移（分钟）
    int m_sunriseMin = 360;    // Default sunrise 06:00 / 默认日出 06:00
    int m_sunsetMin = 1080;    // Default sunset  18:00 / 默认日落 18:00
    int m_currentMin = 720;    // Default noon 12:00 / 默认当前时间 12:00
    float m_solarAltitude = 45.0f;  // Sun elevation above horizon (°) / 太阳高度角（度）
    float m_solarAzimuth = 180.0f;  // Sun azimuth from north (°) / 太阳方位角（度，从北顺时针）
    float m_moonAltitude = 30.0f;   // Moon elevation above horizon (°) / 月亮高度角（度）
    float m_moonAzimuth = 90.0f;    // Moon azimuth from north (°) / 月亮方位角（度）
    float m_moonPhase = 4.0f;       // Moon phase icon index / 月相图标索引
    float m_moonIllum = 1.0f;       // Moon illumination percentage (0–1) / 月照率（0–1）

    // calcSolarPosition — Simplified solar position algorithm / 简化太阳位置算法
    void calcSolarPosition(int dayOfYear, int minuteOfDay);
};
