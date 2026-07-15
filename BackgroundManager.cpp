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

void BackgroundManager::setDebugTime(qreal hour)
{
    if (m_controlMode != 1) {
        qDebug() << "[BackgroundManager] setDebugTime ignored — not in debug mode";
        return;
    }
    int minute = qBound(0, static_cast<int>(hour * 60.0), 1440);
    m_astronomy.updateByMinute(minute);

    QVariantMap ch = buildAstronomyChanges();
    QVariantMap atmos = buildAtmosphereChanges();
    ch.insert(atmos);

    int h = minute / 60;
    int m = minute % 60;
    qDebug() << "[BackgroundManager] setDebugTime:" << h << ":" << m
             << "→ solarAlt=" << m_astronomy.solarAltitude() << "°";

    commitSkyState(ch);
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
    float dp = m_astronomy.dayProgress();

    // ── 7 段天空色表 ──
    struct Seg { float start; const char *name; QColor z, h, a; };
    static const Seg SEGS[] = {
        { -999.f, "深夜",   QColor("#0a0a1a"), QColor("#0d0d28"), QColor("#050510") },
        { -0.30f, "蓝调",   QColor("#1a2a5a"), QColor("#4a3060"), QColor("#0a0a20") },
        {  0.00f, "金粉",   QColor("#4a6fa5"), QColor("#f4a460"), QColor("#e07050") },
        {  0.15f, "白天",   QColor("#4a90d9"), QColor("#87ceeb"), QColor("#c8e0f0") },
        {  0.70f, "暖午后", QColor("#5a8ab5"), QColor("#d4996a"), QColor("#c0b0a0") },
        {  0.90f, "橙红",   QColor("#3a5a8a"), QColor("#e07840"), QColor("#a03030") },
        {  1.00f, "紫调",   QColor("#2a1a4a"), QColor("#602040"), QColor("#0a0a20") },
        {  999.f, nullptr, {}, {}, {} },
    };
    static const int SEG_COUNT = std::size(SEGS) - 1;  // 去掉哨兵

    // 查找 dp 所在段
    int idx = 0;
    for (int i = 1; i < SEG_COUNT; ++i) {
        if (dp >= SEGS[i].start)
            idx = i;
    }
    int next = qMin(idx + 1, SEG_COUNT - 1);

    // 段内插值 t ∈ [0,1]
    float segLen = SEGS[next].start - SEGS[idx].start;
    float t = (segLen > 0.001f)
        ? qBound(0.0f, (dp - SEGS[idx].start) / segLen, 1.0f)
        : 0.0f;

    QColor zenith  = mixColor(SEGS[idx].z, SEGS[next].z, t);
    QColor horizon = mixColor(SEGS[idx].h, SEGS[next].h, t);
    QColor ambient = mixColor(SEGS[idx].a, SEGS[next].a, t);

    // ── 光照/曝光/星空 ──
    float exposure = 1.0f;
    float twilightFactor = 0.0f;
    float starVis = 0.0f;
    float moonFactor = qBound(0.0f, (m_skyState.moonIllum + 1.0f) * 0.5f, 1.0f);

    if (dp < 0.0f) {
        // 日出前: 深夜/蓝调
        float nightBlend = qBound(0.0f, dp / 0.3f + 1.0f, 1.0f);  // -0.3→0, 0→1
        exposure = 0.3f + nightBlend * 0.3f;
        starVis = (1.0f - nightBlend) * 0.8f + moonFactor * 0.2f;
    } else if (dp < 0.15f) {
        // 金粉→白天过渡
        float p = dp / 0.15f;  // 0→1
        exposure = 0.6f + 1.0f * p;
        twilightFactor = 1.0f - p;
        starVis = (1.0f - p) * 0.8f;
    } else if (dp <= 0.90f) {
        // 白天/暖午后
        float baseExp = (dp < 0.70f) ? 1.6f : 1.5f;
        exposure = baseExp;
        starVis = 0.0f;
    } else if (dp <= 1.0f) {
        // 橙红/紫调过渡
        float p = (dp - 0.9f) / 0.1f;  // 0→1
        exposure = 1.6f - 1.0f * p;
        twilightFactor = p;
        starVis = p * 0.8f;
    } else {
        // 日落后
        float nightBlend = qBound(0.0f, (dp - 1.0f) / 0.3f, 1.0f);  // 1.0→1→0
        nightBlend = 1.0f - qMin(nightBlend, 1.0f);
        exposure = 0.3f + nightBlend * 0.3f;
        starVis = (1.0f - nightBlend) * 0.8f + moonFactor * 0.2f;
    }

    // ── 天气调制曝光 ──
    float weatherMod = 0.0f;
    if (m_skyState.cloudCoverage < 0.2f && m_skyState.rainIntensity < 0.01f && m_skyState.snowIntensity < 0.01f) {
        weatherMod = 0.2f;
    } else if (m_skyState.cloudCoverage > 0.7f || m_skyState.rainIntensity > 0.3f || m_skyState.snowIntensity > 0.3f) {
        weatherMod = -0.15f;
    }
    exposure = qMax(0.1f, exposure + weatherMod);

    QVariantMap ch;
    ch["zenithColor"]    = zenith;
    ch["horizonColor"]   = horizon;
    ch["ambientColor"]   = ambient;
    ch["exposure"]       = static_cast<double>(exposure);
    ch["twilightFactor"] = static_cast<double>(qBound(0.0f, twilightFactor, 1.0f));
    ch["starVisibility"] = static_cast<double>(qBound(0.0f, starVis, 1.0f));

    int h = m_astronomy.currentMin() / 60;
    int m = m_astronomy.currentMin() % 60;
    // 用 QDebug 分拆确保无模板歧义
    qDebug() << "[Atm] dp=" << dp
             << "seg=" << SEGS[idx].name
             << "t=" << t;
    qDebug() << "   [Atm] zenith=" << zenith.name()
             << "horizon=" << horizon.name()
             << "ambient=" << ambient.name();
    qDebug() << "   [Atm] exp=" << exposure
             << "twl=" << twilightFactor
             << "stars=" << starVis;

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
