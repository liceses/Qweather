#pragma once
#include <QColor>
#include <QObject>

// SkyState: 统一渲染状态 — C++ struct 暴露给 QML
// 所有字段通过 Q_PROPERTY 暴露，QML ShaderEffect 直接绑定
struct SkyState {
    Q_GADGET
    // 天文
    Q_PROPERTY(float solarAltitude  MEMBER solarAltitude)
    Q_PROPERTY(float solarAzimuth   MEMBER solarAzimuth)
    Q_PROPERTY(float moonAltitude   MEMBER moonAltitude)
    Q_PROPERTY(float moonAzimuth    MEMBER moonAzimuth)
    Q_PROPERTY(float moonPhase      MEMBER moonPhase)
    Q_PROPERTY(float moonIllum      MEMBER moonIllum)
    // 大气
    Q_PROPERTY(QColor zenithColor   MEMBER zenithColor)
    Q_PROPERTY(QColor horizonColor  MEMBER horizonColor)
    Q_PROPERTY(QColor ambientColor  MEMBER ambientColor)
    Q_PROPERTY(float exposure       MEMBER exposure)
    Q_PROPERTY(float twilightFactor MEMBER twilightFactor)
    // 天气
    Q_PROPERTY(float cloudCoverage  MEMBER cloudCoverage)
    Q_PROPERTY(float rainIntensity  MEMBER rainIntensity)
    Q_PROPERTY(float snowIntensity  MEMBER snowIntensity)
    Q_PROPERTY(float fogDensity     MEMBER fogDensity)
    Q_PROPERTY(float lightningProb  MEMBER lightningProb)
    Q_PROPERTY(float starVisibility MEMBER starVisibility)
    // 变体
    Q_PROPERTY(int cloudVariant   MEMBER cloudVariant)
    Q_PROPERTY(int fogVariant     MEMBER fogVariant)
    Q_PROPERTY(int weatherVariant MEMBER weatherVariant)

public:
    // 天文
    float solarAltitude = 45.0f;
    float solarAzimuth = 180.0f;
    float moonAltitude = 30.0f;
    float moonAzimuth = 90.0f;
    float moonPhase = 4.0f;
    float moonIllum = 1.0f;

    // 大气
    QColor zenithColor{"#4a90d9"};
    QColor horizonColor{"#87ceeb"};
    QColor ambientColor{"#c8e0f0"};
    float exposure = 1.0f;
    float twilightFactor = 0.0f;

    // 天气
    float cloudCoverage = 0.0f;
    float rainIntensity = 0.0f;
    float snowIntensity = 0.0f;
    float fogDensity = 0.0f;
    float lightningProb = 0.0f;
    float starVisibility = 0.0f;

    // 变体
    int cloudVariant = 0;
    int fogVariant = 0;
    int weatherVariant = 0;

    // 验证输出
    QString dump() const {
        return QStringLiteral(
            "SkyState{solarAlt=%1 solarAz=%2 moonAlt=%3 moonAz=%4 "
            "cloud=%5 rain=%6 snow=%7 fog=%8 lightning=%9 stars=%10 "
            "twilight=%11 exposure=%12 cloudV=%13 fogV=%14 rainV=%15}")
            .arg(solarAltitude, 0, 'f', 1)
            .arg(solarAzimuth, 0, 'f', 1)
            .arg(moonAltitude, 0, 'f', 1)
            .arg(moonAzimuth, 0, 'f', 1)
            .arg(cloudCoverage, 0, 'f', 2)
            .arg(rainIntensity, 0, 'f', 2)
            .arg(snowIntensity, 0, 'f', 2)
            .arg(fogDensity, 0, 'f', 2)
            .arg(lightningProb, 0, 'f', 2)
            .arg(starVisibility, 0, 'f', 2)
            .arg(twilightFactor, 0, 'f', 2)
            .arg(exposure, 0, 'f', 2)
            .arg(cloudVariant)
            .arg(fogVariant)
            .arg(weatherVariant);
    }
};

Q_DECLARE_METATYPE(SkyState)
