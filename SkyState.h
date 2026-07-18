#pragma once
#include <QColor>
#include <QObject>

// SkyState — Unified rendering state exposed to QML
// 统一渲染状态，通过 Q_PROPERTY 暴露所有字段供 QML ShaderEffect 直接绑定
struct SkyState {
    Q_GADGET
    // Astronomy — Sun & moon position for sky rendering / 天文：太阳/月亮位置与月相
    Q_PROPERTY(float solarAltitude  MEMBER solarAltitude)
    Q_PROPERTY(float solarAzimuth   MEMBER solarAzimuth)
    Q_PROPERTY(float moonAltitude   MEMBER moonAltitude)
    Q_PROPERTY(float moonAzimuth    MEMBER moonAzimuth)
    Q_PROPERTY(float moonPhase      MEMBER moonPhase)
    Q_PROPERTY(float moonIllum      MEMBER moonIllum)
    // Atmosphere — Sky dome color & lighting / 大气：天顶色、地平线色、环境色与曝光
    Q_PROPERTY(QColor zenithColor   MEMBER zenithColor)
    Q_PROPERTY(QColor horizonColor  MEMBER horizonColor)
    Q_PROPERTY(QColor ambientColor  MEMBER ambientColor)
    Q_PROPERTY(float exposure       MEMBER exposure)
    Q_PROPERTY(float twilightFactor MEMBER twilightFactor)
    // Weather — Cloud, rain, snow, fog, lightning, stars / 天气：云量、雨雪强度、雾密度、闪电概率、星空可见度
    Q_PROPERTY(float cloudCoverage  MEMBER cloudCoverage)
    Q_PROPERTY(float rainIntensity  MEMBER rainIntensity)
    Q_PROPERTY(float snowIntensity  MEMBER snowIntensity)
    Q_PROPERTY(float fogDensity     MEMBER fogDensity)
    Q_PROPERTY(float lightningProb  MEMBER lightningProb)
    Q_PROPERTY(float starVisibility MEMBER starVisibility)
    // Variants — Visual sub-type selection / 变体：云、雾、天气视觉子类型选择
    Q_PROPERTY(int cloudVariant   MEMBER cloudVariant)
    Q_PROPERTY(int fogVariant     MEMBER fogVariant)
    Q_PROPERTY(int weatherVariant MEMBER weatherVariant)

public:
    // Astronomy fields / 天文字段：太阳高度角/方位角、月亮高度角/方位角、月相、月照率
    float solarAltitude = 45.0f;
    float solarAzimuth = 180.0f;
    float moonAltitude = 30.0f;
    float moonAzimuth = 90.0f;
    float moonPhase = 4.0f;
    float moonIllum = 1.0f;

    // Atmosphere fields / 大气字段：天顶色、地平线色、环境色、曝光度、黄昏因子
    QColor zenithColor{"#4a90d9"};
    QColor horizonColor{"#87ceeb"};
    QColor ambientColor{"#c8e0f0"};
    float exposure = 1.0f;
    float twilightFactor = 0.0f;

    // Weather fields / 天气字段：云量、雨强、雪强、雾密度、闪电概率、星空可见度
    float cloudCoverage = 0.0f;
    float rainIntensity = 0.0f;
    float snowIntensity = 0.0f;
    float fogDensity = 0.0f;
    float lightningProb = 0.0f;
    float starVisibility = 0.0f;

    // Variant fields / 变体字段：云、雾、天气视觉子类型
    int cloudVariant = 0;
    int fogVariant = 0;
    int weatherVariant = 0;

    // dump — Debug string for state verification / 调试用状态输出
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

// Register SkyState as Qt metatype for QML interop / 注册元类型以便在 QML 中传递
Q_DECLARE_METATYPE(SkyState)
