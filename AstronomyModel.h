#pragma once
#include <QObject>
#include <QDateTime>
#include <QtMath>

// AstronomyModel: 太阳/月亮位置计算
// 简化版天文公式，用于驱动 SkyLayer 的天空渲染
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

    // 输入
    void setLocation(float lat, float lon);
    void setSunTimes(const QString &sunrise, const QString &sunset);
    void setMoonData(int phaseIcon, float illumination);
    void update(qint64 nowMsecs);
    void updateByMinute(int minuteOfDay);  // Debug 时间控制

    // 输出（只读）
    float solarAltitude()  const { return m_solarAltitude; }
    float solarAzimuth()   const { return m_solarAzimuth; }
    float moonAltitude()   const { return m_moonAltitude; }
    float moonAzimuth()    const { return m_moonAzimuth; }
    float moonPhase()      const { return m_moonPhase; }
    float moonIllum()      const { return m_moonIllum; }

    // 派生值
    float sunProgress() const;       // 0=dawn, 0.5=noon, 1=dusk
    float dayProgress() const;       // 无 clamp, -0.5~1.5 范围
    bool isNight() const;
    int sunriseMin() const { return m_sunriseMin; }
    int sunsetMin()  const { return m_sunsetMin; }
    int currentMin() const { return m_currentMin; }
    int dayOfYear()  const { return m_dayOfYear; }

signals:
    void updated();

private:
    float m_lat = 39.9f, m_lon = 116.4f;       // 默认北京
    int m_dayOfYear = 196;       // 默认 7 月 15 日
    int m_lonOffset = 0;         // 经度时区偏移（分钟）
    int m_sunriseMin = 360;    // 06:00
    int m_sunsetMin = 1080;    // 18:00
    int m_currentMin = 720;    // 12:00
    float m_solarAltitude = 45.0f;
    float m_solarAzimuth = 180.0f;
    float m_moonAltitude = 30.0f;
    float m_moonAzimuth = 90.0f;
    float m_moonPhase = 4.0f;
    float m_moonIllum = 1.0f;

    void calcSolarPosition(int dayOfYear, int minuteOfDay);
};
