#include "BackgroundManager.h"
#include "TransitionController.h"
#include <QDateTime>
#include <QDebug>
#include <QtMath>

BackgroundManager::BackgroundManager(QObject *parent)
    : QObject(parent)
{
    // 天文定时刷新: 每 60s 更新一次
    m_astronomyTimer.setInterval(60000);
    connect(&m_astronomyTimer, &QTimer::timeout, this, &BackgroundManager::onAstronomyTimer);
    m_astronomyTimer.start();

    // 输出初始状态
    qDebug() << "[BackgroundManager] created, initial skyState:" << m_skyState.dump();
    qDebug() << "[BackgroundManager] astronomyTimer started, interval=60000ms";
}

void BackgroundManager::updateWeather(int iconCode, bool isDay)
{
    if (m_controlMode == 1) {
        qDebug() << "[BackgroundManager] updateWeather SKIPPED (debug mode)"
                 << "code=" << iconCode << "isDay=" << isDay;
        return;
    }

    WeatherProfile p = m_profiles.fromCode(iconCode, isDay);
    m_skyState.cloudCoverage = p.cloudCoverage;
    m_skyState.rainIntensity = (p.weatherParticle == "rain")  ? p.intensity : 0.0f;
    m_skyState.snowIntensity = (p.weatherParticle == "snow") ? p.intensity : 0.0f;
    m_skyState.fogDensity    = p.fogIntensity;
    m_skyState.lightningProb = p.lightningActive ? 1.0f : 0.0f;
    m_skyState.starVisibility = (!isDay) ? 0.8f : 0.0f;

    qDebug() << "[BackgroundManager] updateWeather: code=" << iconCode
             << "isDay=" << isDay
             << "→" << m_skyState.dump();

    emit skyStateChanged();
}

void BackgroundManager::updateSunTimes(const QString &sunrise, const QString &sunset)
{
    qDebug() << "[BackgroundManager] updateSunTimes:" << sunrise << "-" << sunset;
    m_astronomy.setSunTimes(sunrise, sunset);
    m_astronomy.update(QDateTime::currentMSecsSinceEpoch());
    syncAstronomyToSkyState();
    updateAtmosphere();
    emit skyStateChanged();
}

void BackgroundManager::updateMoonData(int phaseIcon, float illumination)
{
    qDebug() << "[BackgroundManager] updateMoonData: phaseIcon=" << phaseIcon
             << "illumination=" << illumination;
    m_astronomy.setMoonData(phaseIcon, illumination);
    m_skyState.moonPhase = static_cast<float>(phaseIcon);
    m_skyState.moonIllum = illumination;
    emit skyStateChanged();
}

void BackgroundManager::setLocation(float lat, float lon)
{
    qDebug() << "[BackgroundManager] setLocation: lat=" << lat << "lon=" << lon;
    m_astronomy.setLocation(lat, lon);
}

void BackgroundManager::setParallax(float x, float y)
{
    Q_UNUSED(x)
    Q_UNUSED(y)
    // 视差数据传递给 Shader 由 QML 端直接绑定，C++ 仅中转
}

void BackgroundManager::enterDebugMode()
{
    if (m_controlMode == 1) return;
    m_controlMode = 1;
    m_debugSkyState = m_skyState;  // 保存当前状态快照
    qDebug() << "[BackgroundManager] >>> enterDebugMode, snapshot saved:"
             << m_debugSkyState.dump();
    emit controlModeChanged();
    emit debugModeEntered();
}

void BackgroundManager::exitDebugMode()
{
    if (m_controlMode == 0) return;
    m_controlMode = 0;
    // 恢复自动模式状态
    m_skyState = m_debugSkyState;
    qDebug() << "[BackgroundManager] <<< exitDebugMode, restored:"
             << m_skyState.dump();
    emit controlModeChanged();
    emit skyStateChanged();
    emit debugModeExited();
}

void BackgroundManager::setDebugField(const QString &field, float value)
{
    if (m_controlMode != 1) {
        qDebug() << "[BackgroundManager] setDebugField ignored — not in debug mode";
        return;
    }

    qDebug() << "[BackgroundManager] setDebugField:" << field << "=" << value;

    // 通过反射设置 SkyState 字段
    if (field == "cloudCoverage")  m_skyState.cloudCoverage = qBound(0.0f, value, 1.0f);
    else if (field == "rainIntensity")  m_skyState.rainIntensity = qBound(0.0f, value, 1.0f);
    else if (field == "snowIntensity")  m_skyState.snowIntensity = qBound(0.0f, value, 1.0f);
    else if (field == "fogDensity")     m_skyState.fogDensity = qBound(0.0f, value, 1.0f);
    else if (field == "lightningProb")  m_skyState.lightningProb = qBound(0.0f, value, 1.0f);
    else if (field == "starVisibility") m_skyState.starVisibility = qBound(0.0f, value, 1.0f);
    else if (field == "solarAltitude")  m_skyState.solarAltitude = qBound(-90.0f, value, 90.0f);
    else if (field == "moonAltitude")   m_skyState.moonAltitude = qBound(-90.0f, value, 90.0f);
    else if (field == "twilightFactor") m_skyState.twilightFactor = qBound(0.0f, value, 1.0f);
    else if (field == "exposure")       m_skyState.exposure = qBound(0.1f, value, 2.0f);
    else {
        qDebug() << "[BackgroundManager] unknown debug field:" << field;
        return;
    }

    emit skyStateChanged();

    // 通知 TransitionController（调试模式下更新 Layer 状态）
    if (m_transitionCtrl) {
        m_transitionCtrl->setSkyState(m_skyState);
    }
}

void BackgroundManager::stepTime(int minutes)
{
    // 模拟时间前进 minutes 分钟
    // 用于 Debug 面板的"冻结时间 + 步进"功能
    Q_UNUSED(minutes)
    qDebug() << "[BackgroundManager] stepTime:" << minutes << "min (not implemented yet)";
    // TODO: 在 Debug 模式下模拟时间流逝，更新太阳位置
}

void BackgroundManager::setDebugSkyState(const SkyState &s)
{
    m_debugSkyState = s;
    if (m_controlMode == 1) {
        m_skyState = s;
        emit skyStateChanged();
    }
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

void BackgroundManager::onAstronomyTimer()
{
    if (m_controlMode == 1) {
        qDebug() << "[BackgroundManager] astronomyTimer SKIPPED (debug mode)";
        return;
    }
    m_astronomy.update(QDateTime::currentMSecsSinceEpoch());
    syncAstronomyToSkyState();
    updateAtmosphere();
    qDebug() << "[BackgroundManager] astronomyTimer tick →" << m_skyState.dump();
    emit skyStateChanged();
}

void BackgroundManager::syncAstronomyToSkyState()
{
    m_skyState.solarAltitude = m_astronomy.solarAltitude();
    m_skyState.solarAzimuth  = m_astronomy.solarAzimuth();
    m_skyState.moonAltitude  = m_astronomy.moonAltitude();
    m_skyState.moonAzimuth   = m_astronomy.moonAzimuth();
    m_skyState.moonPhase     = m_astronomy.moonPhase();
    m_skyState.moonIllum     = m_astronomy.moonIllum();
}

void BackgroundManager::updateAtmosphere()
{
    float sp = m_astronomy.sunProgress();
    bool night = m_astronomy.isNight();

    // 7 时段 × 3 色: 根据 sunProgress 混合天空色
    // 简化版: 2 段混合（白天/黄昏/夜晚）
    QColor dayZenith("#4a90d9"), dayHorizon("#87ceeb"), dayAmbient("#c8e0f0");
    QColor duskZenith("#c05850"), duskHorizon("#e89560"), duskAmbient("#906050");
    QColor nightZenith("#0a0a2e"), nightHorizon("#1a1a3e"), nightAmbient("#15152e");

    QColor zenith, horizon, ambient;
    float twilight = 0.0f;

    if (night) {
        // 夜晚: 月亮位置决定色调偏移
        float moonFactor = (m_skyState.moonIllum + 1.0f) * 0.5f;
        zenith  = mixColor(nightZenith,  duskZenith,  moonFactor * 0.3f);
        horizon = mixColor(nightHorizon, duskHorizon, moonFactor * 0.3f);
        ambient = mixColor(nightAmbient, duskAmbient, moonFactor * 0.3f);
        m_skyState.exposure = 0.8f;
    } else if (sp < 0.15f || sp > 0.85f) {
        // 黄昏/黎明
        float dp = (sp < 0.15f) ? (sp / 0.15f) : ((1.0f - sp) / 0.15f);
        twilight = 1.0f - dp;
        zenith  = mixColor(dayZenith,  duskZenith,  twilight);
        horizon = mixColor(dayHorizon, duskHorizon, twilight);
        ambient = mixColor(dayAmbient, duskAmbient, twilight);
        m_skyState.exposure = 0.9f + 0.1f * dp;
        m_skyState.starVisibility = (1.0f - dp) * 0.3f;
    } else {
        // 白天
        zenith  = dayZenith;
        horizon = dayHorizon;
        ambient = dayAmbient;
        m_skyState.exposure = 1.0f;
        m_skyState.starVisibility = 0.0f;
    }

    m_skyState.zenithColor   = zenith;
    m_skyState.horizonColor  = horizon;
    m_skyState.ambientColor  = ambient;
    m_skyState.twilightFactor = qBound(0.0f, twilight, 1.0f);

    qDebug() << "[BackgroundManager] updateAtmosphere: sunProgress=" << sp
             << "night=" << night
             << "zenith=" << zenith.name()
             << "horizon=" << horizon.name()
             << "twilight=" << twilight
             << "exposure=" << m_skyState.exposure;
}

QColor BackgroundManager::mixColor(const QColor &a, const QColor &b, float t)
{
    float r = a.redF()   * (1.0f - t) + b.redF()   * t;
    float g = a.greenF() * (1.0f - t) + b.greenF() * t;
    float bv = a.blueF() * (1.0f - t) + b.blueF() * t;
    return QColor::fromRgbF(r, g, bv, 1.0f);
}
