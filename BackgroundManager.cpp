#include "BackgroundManager.h"
#include "TransitionController.h"
#include <QDateTime>
#include <QDebug>
#include <QtMath>
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>

BackgroundManager::BackgroundManager(QObject *parent)
    : QObject(parent)
{
    m_astronomyTimer.setInterval(60000);
    connect(&m_astronomyTimer, &QTimer::timeout, this, &BackgroundManager::onAstronomyTimer);
    m_astronomyTimer.start();

    m_lerpTimer.setInterval(16);
    connect(&m_lerpTimer, &QTimer::timeout, this, &BackgroundManager::tickLerp);

    QString cfgDir = QCoreApplication::applicationDirPath();
    QDir().mkpath(cfgDir);
    m_configPath = cfgDir + "/weather_profiles.json";
    m_profiles.loadFromFile(m_configPath);

    qDebug() << "[BackgroundManager] created, initial:" << m_skyState.dump();
    qDebug() << "[BackgroundManager] astronomyTimer started, interval=60000ms";
}

// ==================== commitSkyState ====================

void BackgroundManager::commitSkyState(const QVariantMap &changes)
{
    bool changed = false;
    auto applyFloat = [&](const char *key, float &member, float minV, float maxV) {
        if (changes.contains(key)) {
            member = qBound(minV, static_cast<float>(changes[key].toDouble()), maxV);
            changed = true;
        }
    };
    auto applyInt = [&](const char *key, int &member, int minV, int maxV) {
        if (changes.contains(key)) {
            member = qBound(minV, changes[key].toInt(), maxV);
            changed = true;
        }
    };
    auto applyColor = [&](const char *key, QColor &member) {
        if (changes.contains(key)) {
            member = qvariant_cast<QColor>(changes[key]);
            changed = true;
        }
    };

    applyFloat("solarAltitude",  m_skyState.solarAltitude,  -90.0f, 90.0f);
    applyFloat("solarAzimuth",   m_skyState.solarAzimuth,   0.0f, 360.0f);
    applyFloat("moonAltitude",   m_skyState.moonAltitude,   -90.0f, 90.0f);
    applyFloat("moonAzimuth",    m_skyState.moonAzimuth,    0.0f, 360.0f);
    applyFloat("moonPhase",      m_skyState.moonPhase,      0.0f, 8.0f);
    applyFloat("moonIllum",      m_skyState.moonIllum,      -1.0f, 1.0f);

    applyFloat("cloudCoverage",  m_skyState.cloudCoverage,  0.0f, 1.0f);
    applyFloat("rainIntensity",  m_skyState.rainIntensity,  0.0f, 1.0f);
    applyFloat("snowIntensity",  m_skyState.snowIntensity,  0.0f, 1.0f);
    applyFloat("fogDensity",     m_skyState.fogDensity,     0.0f, 1.0f);
    applyFloat("lightningProb",  m_skyState.lightningProb,  0.0f, 1.0f);
    applyFloat("starVisibility", m_skyState.starVisibility, 0.0f, 1.0f);

    applyInt("cloudVariant",   m_skyState.cloudVariant,   0, 3);
    applyInt("fogVariant",     m_skyState.fogVariant,     0, 3);
    applyInt("weatherVariant", m_skyState.weatherVariant, 0, 3);

    applyFloat("exposure",       m_skyState.exposure,      0.0f, 3.0f);
    applyFloat("twilightFactor", m_skyState.twilightFactor, 0.0f, 1.0f);

    applyColor("zenithColor",  m_skyState.zenithColor);
    applyColor("horizonColor", m_skyState.horizonColor);
    applyColor("ambientColor", m_skyState.ambientColor);

    if (changed) {
        if (m_transitionCtrl)
            m_transitionCtrl->setSkyState(m_skyState);
        emit skyStateChanged();
    }
}

// ==================== Auto 模式入口 ====================

void BackgroundManager::updateWeather(int iconCode, bool isDay)
{
    WeatherProfile p = m_profiles.fromCode(iconCode, isDay);
    QVariantMap ch;
    ch["cloudCoverage"]  = p.cloudCoverage;
    ch["rainIntensity"]  = (p.weatherParticle == "rain")  ? static_cast<double>(p.intensity) : 0.0;
    ch["snowIntensity"]  = (p.weatherParticle == "snow") ? static_cast<double>(p.intensity) : 0.0;
    ch["fogDensity"]     = static_cast<double>(p.fogIntensity);
    ch["lightningProb"]  = p.lightningActive ? 1.0 : 0.0;
    ch["starVisibility"] = (!isDay) ? 0.8 : 0.0;

    QVariantMap baseAtmos = buildAtmosphereChanges();
    double baseExp = baseAtmos.contains("exposure") ? baseAtmos["exposure"].toDouble() : 1.0;

    float cloudDim = 1.0f - 0.45f * p.cloudCoverage;
    float rainDim  = (p.weatherParticle == "rain")  ? (1.0f - 0.45f * p.intensity) : 1.0f;
    float snowDim  = (p.weatherParticle == "snow")  ? (1.0f - 0.25f * p.intensity) : 1.0f;
    float fogDim   = (p.fogActive) ? (1.0f - 0.35f * p.fogIntensity) : 1.0f;
    float weatherScale = qMax(0.15f, cloudDim * rainDim * snowDim * fogDim);
    ch["exposure"] = baseExp * weatherScale + p.exposureOffset;

    m_lastWeatherScale = weatherScale;

    qDebug() << "[BackgroundManager] updateWeather: code=" << iconCode
             << "isDay=" << isDay
             << "mode=" << (m_controlMode == 0 ? "Auto" : "Debug");
    m_currentWeatherCode = iconCode;
    m_currentIsDay = isDay;
    emit currentWeatherChanged();
    commitSkyState(ch);
}

void BackgroundManager::updateSunTimes(const QString &sunrise, const QString &sunset)
{
    m_astronomy.setSunTimes(sunrise, sunset);
    m_astronomy.update(QDateTime::currentMSecsSinceEpoch());
    QVariantMap ch = buildAstronomyChanges();
    QVariantMap atmos = buildAtmosphereChanges();
    ch.insert(atmos);
    if (ch.contains("exposure"))
        ch["exposure"] = ch["exposure"].toDouble() * m_lastWeatherScale;
    qDebug() << "[BackgroundManager] updateSunTimes:" << sunrise << "-" << sunset;
    commitSkyState(ch);
}

void BackgroundManager::updateMoonData(int phaseIcon, float illumination)
{
    m_astronomy.setMoonData(phaseIcon, illumination);
    QVariantMap ch;
    ch["moonPhase"] = static_cast<double>(m_astronomy.moonPhase());
    ch["moonIllum"] = static_cast<double>(m_astronomy.moonIllum());
    commitSkyState(ch);
}

void BackgroundManager::setLocation(float lat, float lon)
{
    qDebug() << "[BackgroundManager] setLocation: lat=" << lat << "lon=" << lon;
    m_lerpFrom[0] = m_skyState.solarAltitude;
    m_lerpFrom[1] = m_skyState.solarAzimuth;
    m_lerpFrom[2] = m_skyState.moonAltitude;
    m_lerpFrom[3] = m_skyState.moonAzimuth;
    m_lerpFrom[4] = m_skyState.starVisibility;
    m_lerpFrom[5] = m_skyState.twilightFactor;

    m_astronomy.setLocation(lat, lon);
    m_astronomy.update(QDateTime::currentMSecsSinceEpoch());
    m_lerpTo[0] = m_astronomy.solarAltitude();
    m_lerpTo[1] = m_astronomy.solarAzimuth();
    m_lerpTo[2] = m_astronomy.moonAltitude();
    m_lerpTo[3] = m_astronomy.moonAzimuth();
    m_lerpTo[4] = m_skyState.starVisibility;
    m_lerpTo[5] = m_skyState.twilightFactor;

    m_lerpTick = 0;
    m_lerpTimer.start();
}

void BackgroundManager::setParallax(float x, float y)
{
    Q_UNUSED(x) Q_UNUSED(y)
}

// ==================== Debug 模式 ====================

void BackgroundManager::enterDebugMode()
{
    if (m_controlMode == 1) return;
    m_controlMode = 1;
    qDebug() << "[BackgroundManager] >>> enterDebugMode";
    emit controlModeChanged();
}

void BackgroundManager::exitDebugMode()
{
    if (m_controlMode == 0) return;
    m_controlMode = 0;
    qDebug() << "[BackgroundManager] <<< exitDebugMode";
    emit controlModeChanged();
}

void BackgroundManager::setDebugTime(qreal hour)
{
    if (m_controlMode != 1) {
        qDebug() << "[BackgroundManager] setDebugTime ignored - not in debug mode";
        return;
    }
    int minute = qBound(0, static_cast<int>(hour * 60), 1439);
    m_astronomy.updateByMinute(minute);

    QVariantMap atmos = buildAtmosphereChanges();
    QVariantMap changes;
    changes["solarAltitude"] = static_cast<double>(m_astronomy.solarAltitude());
    changes["solarAzimuth"]  = static_cast<double>(m_astronomy.solarAzimuth());
    changes["moonAltitude"]  = static_cast<double>(m_astronomy.moonAltitude());
    changes["moonAzimuth"]   = static_cast<double>(m_astronomy.moonAzimuth());
    changes["zenithColor"]   = atmos["zenithColor"];
    changes["horizonColor"]  = atmos["horizonColor"];
    changes["ambientColor"]  = atmos["ambientColor"];
    changes["exposure"]      = atmos["exposure"];
    changes["twilightFactor"] = atmos["twilightFactor"];
    changes["starVisibility"] = atmos["starVisibility"];

    qDebug() << "[BackgroundManager] setDebugTime:" << QString("%1:%2")
        .arg(minute/60,2,10,QLatin1Char('0'))
        .arg(minute%60,2,10,QLatin1Char('0'))
        << "solarAlt=" << m_astronomy.solarAltitude();
    commitSkyState(changes);
}

// ==================== 天文定时器 ====================

void BackgroundManager::onAstronomyTimer()
{
    m_astronomy.update(QDateTime::currentMSecsSinceEpoch());
    QVariantMap ch = buildAstronomyChanges();
    QVariantMap atmos = buildAtmosphereChanges();
    ch.insert(atmos);
    if (ch.contains("exposure"))
        ch["exposure"] = ch["exposure"].toDouble() * m_lastWeatherScale;
    qDebug() << "[BackgroundManager] astronomyTimer tick";
    commitSkyState(ch);
}

// ==================== 天文过渡插值 ====================

void BackgroundManager::tickLerp()
{
    m_lerpTick++;
    float t = qMin(1.0f, static_cast<float>(m_lerpTick) / LERP_DURATION);
    t = t * t * (3.0f - 2.0f * t);

    QVariantMap ch;
    ch["solarAltitude"] = static_cast<double>(m_lerpFrom[0] + (m_lerpTo[0] - m_lerpFrom[0]) * t);
    ch["solarAzimuth"]  = static_cast<double>(m_lerpFrom[1] + (m_lerpTo[1] - m_lerpFrom[1]) * t);
    ch["moonAltitude"]  = static_cast<double>(m_lerpFrom[2] + (m_lerpTo[2] - m_lerpFrom[2]) * t);
    ch["moonAzimuth"]   = static_cast<double>(m_lerpFrom[3] + (m_lerpTo[3] - m_lerpFrom[3]) * t);
    ch["starVisibility"] = static_cast<double>(m_lerpFrom[4] + (m_lerpTo[4] - m_lerpFrom[4]) * t);
    ch["twilightFactor"] = static_cast<double>(m_lerpFrom[5] + (m_lerpTo[5] - m_lerpFrom[5]) * t);
    commitSkyState(ch);

    if (t >= 1.0f) {
        m_lerpTimer.stop();
        qDebug() << "[BackgroundManager] location lerp complete";
    }
}

// ==================== 辅助 ====================

QVariantMap BackgroundManager::buildAstronomyChanges()
{
    QVariantMap ch;
    ch["solarAltitude"] = static_cast<double>(m_astronomy.solarAltitude());
    ch["solarAzimuth"]  = static_cast<double>(m_astronomy.solarAzimuth());
    ch["moonAltitude"]  = static_cast<double>(m_astronomy.moonAltitude());
    ch["moonAzimuth"]   = static_cast<double>(m_astronomy.moonAzimuth());
    ch["moonPhase"]     = static_cast<double>(m_astronomy.moonPhase());
    ch["moonIllum"]     = static_cast<double>(m_astronomy.moonIllum());
    return ch;
}

QVariantMap BackgroundManager::buildAtmosphereChanges()
{
    float dp = m_astronomy.dayProgress();

    struct Seg { float start; const char *name; QColor z, h, a; };
    static const Seg SEGS[] = {
        { -999.f, "deep night", QColor(0x0a,0x0a,0x1a), QColor(0x0d,0x0d,0x28), QColor(0x05,0x05,0x10) },
        { -0.30f, "blue hour",  QColor(0x1a,0x2a,0x5a), QColor(0x4a,0x30,0x60), QColor(0x0a,0x0a,0x20) },
        {  0.00f, "gold hour",  QColor(0x4a,0x6f,0xa5), QColor(0xf4,0xa4,0x60), QColor(0xe0,0x70,0x50) },
        {  0.15f, "day",        QColor(0x4a,0x90,0xd9), QColor(0x87,0xce,0xeb), QColor(0xc8,0xe0,0xf0) },
        {  0.70f, "warm noon",  QColor(0x5a,0x8a,0xb5), QColor(0xd4,0x99,0x6a), QColor(0xc0,0xb0,0xa0) },
        {  0.90f, "orange",     QColor(0x3a,0x5a,0x8a), QColor(0xe0,0x78,0x40), QColor(0xa0,0x30,0x30) },
        {  1.00f, "purple",     QColor(0x2a,0x1a,0x4a), QColor(0x60,0x20,0x40), QColor(0x0a,0x0a,0x20) },
        {  999.f, nullptr, {}, {}, {} },
    };
    static const int SEG_COUNT = std::size(SEGS) - 1;

    int idx = 0;
    for (int i = 1; i < SEG_COUNT; ++i) {
        if (dp >= SEGS[i].start)
            idx = i;
    }
    int next = qMin(idx + 1, SEG_COUNT - 1);

    float segLen = SEGS[next].start - SEGS[idx].start;
    float t = (segLen > 0.001f)
        ? qBound(0.0f, (dp - SEGS[idx].start) / segLen, 1.0f)
        : 0.0f;

    QColor zenith  = mixColor(SEGS[idx].z, SEGS[next].z, t);
    QColor horizon = mixColor(SEGS[idx].h, SEGS[next].h, t);
    QColor ambient = mixColor(SEGS[idx].a, SEGS[next].a, t);

    float exposure = 1.0f;
    float twilightFactor = 0.0f;
    float starVis = 0.0f;
    float moonFactor = qBound(0.0f, (m_skyState.moonIllum + 1.0f) * 0.5f, 1.0f);

    if (dp < 0.0f) {
        float nightBlend = qBound(0.0f, dp / 0.3f + 1.0f, 1.0f);
        exposure = 0.3f + nightBlend * 0.3f;
        starVis = (1.0f - nightBlend) * 0.8f + moonFactor * 0.2f;
    } else if (dp < 0.15f) {
        float p = dp / 0.15f;
        exposure = 0.6f + 1.0f * p;
        twilightFactor = 1.0f - p;
        starVis = (1.0f - p) * 0.8f;
    } else if (dp <= 0.90f) {
        float baseExp = (dp < 0.70f) ? 1.6f : 1.5f;
        exposure = baseExp;
        starVis = 0.0f;
    } else if (dp <= 1.0f) {
        float p = (dp - 0.9f) / 0.1f;
        exposure = 1.6f - 1.0f * p;
        twilightFactor = p;
        starVis = p * 0.8f;
    } else {
        float nightBlend = qBound(0.0f, (dp - 1.0f) / 0.3f, 1.0f);
        nightBlend = 1.0f - qMin(nightBlend, 1.0f);
        exposure = 0.3f + nightBlend * 0.3f;
        starVis = (1.0f - nightBlend) * 0.8f + moonFactor * 0.2f;
    }

    QVariantMap ch;
    ch["zenithColor"]    = zenith;
    ch["horizonColor"]   = horizon;
    ch["ambientColor"]   = ambient;
    ch["exposure"]       = static_cast<double>(exposure);
    ch["twilightFactor"] = static_cast<double>(qBound(0.0f, twilightFactor, 1.0f));
    ch["starVisibility"] = static_cast<double>(qBound(0.0f, starVis, 1.0f));

    qDebug() << "[Atm] dp=" << dp << "seg=" << SEGS[idx].name << "t=" << t;
    qDebug() << "   [Atm] exp=" << exposure << "twl=" << twilightFactor << "stars=" << starVis;

    return ch;
}

QColor BackgroundManager::mixColor(const QColor &a, const QColor &b, float t)
{
    float r = a.redF()   * (1.0f - t) + b.redF()   * t;
    float g = a.greenF() * (1.0f - t) + b.greenF() * t;
    float bv = a.blueF() * (1.0f - t) + b.blueF() * t;
    return QColor::fromRgbF(r, g, bv, 1.0f);
}

QString BackgroundManager::dumpState() const
{
    return QStringLiteral(
        "[BackgroundManager] mode=%1 | %2 | astro: sunrise=%3 sunset=%4")
        .arg(m_controlMode == 0 ? "Auto" : "Debug")
        .arg(m_skyState.dump())
        .arg(m_astronomy.sunriseMin())
        .arg(m_astronomy.sunsetMin());
}

void BackgroundManager::saveProfileForCode(int code)
{
    bool isDay = (code < 150);
    WeatherProfile p;
    p.weatherParticle = m_skyState.rainIntensity > 0.01 ? "rain"
                      : m_skyState.snowIntensity > 0.01 ? "snow" : "";
    p.intensity = qMax(m_skyState.rainIntensity, m_skyState.snowIntensity);
    p.weatherVariant = m_skyState.weatherVariant;
    p.cloudActive = m_skyState.cloudCoverage > 0.01f;
    p.cloudCoverage = m_skyState.cloudCoverage;
    p.cloudVariant = m_skyState.cloudVariant;
    p.fogActive = m_skyState.fogDensity > 0.01f;
    p.fogIntensity = m_skyState.fogDensity;
    p.fogVariant = m_skyState.fogVariant;
    p.lightningActive = m_skyState.lightningProb > 0.5f;
    p.exposureOffset = 0.0f;

    if (isDay)
        m_profiles.setDayProfile(code, p);
    else
        m_profiles.setNightOverride(code, p);
    m_profiles.saveToFile(m_configPath);
    qDebug() << "[BackgroundManager] saved profile for code" << code
             << "isDay=" << isDay << "to" << m_configPath;
}
