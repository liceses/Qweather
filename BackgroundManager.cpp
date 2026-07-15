#include "BackgroundManager.h"
#include "TransitionController.h"
#include <QDateTime>
#include <QDebug>
#include <QtMath>

BackgroundManager::BackgroundManager(QObject *parent)
    : QObject(parent)
{
    m_astronomyTimer.setInterval(60000);
    connect(&m_astronomyTimer, &QTimer::timeout, this, &BackgroundManager::onAstronomyTimer);
    m_astronomyTimer.start();

    qDebug() << "[BackgroundManager] created, initial:" << m_skyState.dump();
    qDebug() << "[BackgroundManager] astronomyTimer started, interval=60000ms";
}

// ==================== 唯一写入入口 ====================

void BackgroundManager::commitSkyState(const QVariantMap &changes)
{
    bool changed = false;

    auto applyFloat = [&](const char *key, float &field, float minVal, float maxVal) {
        auto it = changes.find(key);
        if (it != changes.end()) {
            field = qBound(minVal, static_cast<float>(it->toDouble()), maxVal);
            changed = true;
        }
    };
    auto applyColor = [&](const char *key, QColor &field) {
        auto it = changes.find(key);
        if (it != changes.end()) {
            field = it->value<QColor>();
            changed = true;
        }
    };

    // 天文
    applyFloat("solarAltitude",  m_skyState.solarAltitude,  -90.0f, 90.0f);
    applyFloat("solarAzimuth",   m_skyState.solarAzimuth,     0.0f, 360.0f);
    applyFloat("moonAltitude",   m_skyState.moonAltitude,    -90.0f, 90.0f);
    applyFloat("moonAzimuth",    m_skyState.moonAzimuth,      0.0f, 360.0f);
    applyFloat("moonPhase",      m_skyState.moonPhase,        0.0f, 8.0f);
    applyFloat("moonIllum",      m_skyState.moonIllum,        0.0f, 1.0f);

    // 大气
    applyColor("zenithColor",    m_skyState.zenithColor);
    applyColor("horizonColor",   m_skyState.horizonColor);
    applyColor("ambientColor",   m_skyState.ambientColor);
    applyFloat("exposure",       m_skyState.exposure,        0.1f, 2.0f);
    applyFloat("twilightFactor", m_skyState.twilightFactor,  0.0f, 1.0f);

    // 天气
    applyFloat("cloudCoverage",  m_skyState.cloudCoverage,   0.0f, 1.0f);
    applyFloat("rainIntensity",  m_skyState.rainIntensity,   0.0f, 1.0f);
    applyFloat("snowIntensity",  m_skyState.snowIntensity,   0.0f, 1.0f);
    applyFloat("fogDensity",     m_skyState.fogDensity,      0.0f, 1.0f);
    applyFloat("lightningProb",  m_skyState.lightningProb,   0.0f, 1.0f);
    applyFloat("starVisibility", m_skyState.starVisibility,  0.0f, 1.0f);

    if (!changed) {
        qDebug() << "[BackgroundManager] commitSkyState: no matching keys in changes";
        return;
    }

    qDebug() << "[BackgroundManager] commit:" << m_skyState.dump()
             << "(keys:" << changes.keys() << ")";

    emit skyStateChanged();
    if (m_transitionCtrl)
        m_transitionCtrl->setSkyState(m_skyState);
}

// ==================== Auto 模式 ====================

void BackgroundManager::updateWeather(int iconCode, bool isDay)
{
    if (m_controlMode == 1) {
        qDebug() << "[BackgroundManager] updateWeather SKIPPED (debug mode)"
                 << "code=" << iconCode << "isDay=" << isDay;
        return;
    }

    WeatherProfile p = m_profiles.fromCode(iconCode, isDay);
    QVariantMap ch;
    ch["cloudCoverage"]  = p.cloudCoverage;
    ch["rainIntensity"]  = (p.weatherParticle == "rain")  ? static_cast<double>(p.intensity) : 0.0;
    ch["snowIntensity"]  = (p.weatherParticle == "snow") ? static_cast<double>(p.intensity) : 0.0;
    ch["fogDensity"]     = static_cast<double>(p.fogIntensity);
    ch["lightningProb"]  = p.lightningActive ? 1.0 : 0.0;
    ch["starVisibility"] = (!isDay) ? 0.8 : 0.0;

    qDebug() << "[BackgroundManager] updateWeather: code=" << iconCode << "isDay=" << isDay;
    commitSkyState(ch);
}

void BackgroundManager::updateSunTimes(const QString &sunrise, const QString &sunset)
{
    if (m_controlMode == 1) return;
    qDebug() << "[BackgroundManager] updateSunTimes:" << sunrise << "-" << sunset;
    m_astronomy.setSunTimes(sunrise, sunset);
    m_astronomy.update(QDateTime::currentMSecsSinceEpoch());

    QVariantMap ch = buildAstronomyChanges();
    QVariantMap atmos = buildAtmosphereChanges();
    ch.insert(atmos);
    commitSkyState(ch);
}

void BackgroundManager::updateMoonData(int phaseIcon, float illumination)
{
    if (m_controlMode == 1) return;
    qDebug() << "[BackgroundManager] updateMoonData: phaseIcon=" << phaseIcon
             << "illumination=" << illumination;
    m_astronomy.setMoonData(phaseIcon, illumination);
    m_skyState.moonPhase = static_cast<float>(phaseIcon);
    m_skyState.moonIllum = illumination;

    QVariantMap ch;
    ch["moonPhase"] = static_cast<double>(phaseIcon);
    ch["moonIllum"] = static_cast<double>(illumination);
    commitSkyState(ch);
}

void BackgroundManager::setLocation(float lat, float lon)
{
    qDebug() << "[BackgroundManager] setLocation: lat=" << lat << "lon=" << lon;
    m_astronomy.setLocation(lat, lon);
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
    emit debugModeEntered();
}

void BackgroundManager::exitDebugMode()
{
    if (m_controlMode == 0) return;
    m_controlMode = 0;
    qDebug() << "[BackgroundManager] <<< exitDebugMode";
    emit controlModeChanged();
    emit debugModeExited();
}

// ==================== 定时器 ====================

void BackgroundManager::onAstronomyTimer()
{
    if (m_controlMode == 1) {
        qDebug() << "[BackgroundManager] astronomyTimer SKIPPED (debug mode)";
        return;
    }
    m_astronomy.update(QDateTime::currentMSecsSinceEpoch());
    QVariantMap ch = buildAstronomyChanges();
    QVariantMap atmos = buildAtmosphereChanges();
    ch.insert(atmos);
    qDebug() << "[BackgroundManager] astronomyTimer tick";
    commitSkyState(ch);
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
    float sp = m_astronomy.sunProgress();
    bool night = m_astronomy.isNight();

    QColor dayZenith("#4a90d9"), dayHorizon("#87ceeb"), dayAmbient("#c8e0f0");
    QColor duskZenith("#c05850"), duskHorizon("#e89560"), duskAmbient("#906050");
    QColor nightZenith("#0a0a2e"), nightHorizon("#1a1a3e"), nightAmbient("#15152e");

    QColor zenith, horizon, ambient;
    float twilight = 0.0f;
    float exposure = 1.0f;
    float starVis = m_skyState.starVisibility;

    if (night) {
        float moonFactor = (m_skyState.moonIllum + 1.0f) * 0.5f;
        zenith  = mixColor(nightZenith,  duskZenith,  moonFactor * 0.3f);
        horizon = mixColor(nightHorizon, duskHorizon, moonFactor * 0.3f);
        ambient = mixColor(nightAmbient, duskAmbient, moonFactor * 0.3f);
        exposure = 0.8f;
    } else if (sp < 0.15f || sp > 0.85f) {
        float dp = (sp < 0.15f) ? (sp / 0.15f) : ((1.0f - sp) / 0.15f);
        twilight = 1.0f - dp;
        zenith  = mixColor(dayZenith,  duskZenith,  twilight);
        horizon = mixColor(dayHorizon, duskHorizon, twilight);
        ambient = mixColor(dayAmbient, duskAmbient, twilight);
        exposure = 0.9f + 0.1f * dp;
        starVis = (1.0f - dp) * 0.3f;
    } else {
        zenith  = dayZenith;
        horizon = dayHorizon;
        ambient = dayAmbient;
        exposure = 1.0f;
        starVis = 0.0f;
    }

    QVariantMap ch;
    ch["zenithColor"]   = zenith;
    ch["horizonColor"]  = horizon;
    ch["ambientColor"]  = ambient;
    ch["exposure"]      = static_cast<double>(exposure);
    ch["twilightFactor"] = static_cast<double>(qBound(0.0f, twilight, 1.0f));
    ch["starVisibility"] = static_cast<double>(starVis);

    qDebug() << "[BackgroundManager] buildAtmosphere: sp=" << sp
             << "night=" << night
             << "zenith=" << zenith.name()
             << "exposure=" << exposure;

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
