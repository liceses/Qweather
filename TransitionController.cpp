#include "TransitionController.h"
#include <QDebug>
#include <QtMath>
#include <QTimer>

TransitionController::TransitionController(QObject *parent)
    : QObject(parent)
{
    qDebug() << "[TransitionController] created, all layers inactive";
}

// ==================== Debug tp 覆盖 ====================

void TransitionController::setDebugCloudTP(float v)
{
    v = qBound(0.0f, v, 1.0f);
    if (qFuzzyCompare(m_debugCloudTP, v)) return;
    m_debugCloudTP = v;
    if (v > 0.001f) {
        m_cloudTP = v;
        emit cloudTPChanged();
    } else if (m_cloudActive) {
        m_cloudTP = 1.0f;
        emit cloudTPChanged();
    }
    qDebug() << "[TransitionController] debugCloudTP =" << v;
    emit debugCloudTPChanged();
}

void TransitionController::setDebugWeatherTP(float v)
{
    v = qBound(0.0f, v, 1.0f);
    if (qFuzzyCompare(m_debugWeatherTP, v)) return;
    m_debugWeatherTP = v;
    if (v > 0.001f) {
        m_weatherTP = v;
        emit weatherTPChanged();
    } else if (m_weatherActive) {
        m_weatherTP = 1.0f;
        emit weatherTPChanged();
    }
    qDebug() << "[TransitionController] debugWeatherTP =" << v;
    emit debugWeatherTPChanged();
}

void TransitionController::setDebugFogTP(float v)
{
    v = qBound(0.0f, v, 1.0f);
    if (qFuzzyCompare(m_debugFogTP, v)) return;
    m_debugFogTP = v;
    if (v > 0.001f) {
        m_fogTP = v;
        emit fogTPChanged();
    } else if (m_fogActive) {
        m_fogTP = 1.0f;
        emit fogTPChanged();
    }
    qDebug() << "[TransitionController] debugFogTP =" << v;
    emit debugFogTPChanged();
}

void TransitionController::setFadeInEnabled(bool v)
{
    if (m_fadeInEnabled == v) return;
    m_fadeInEnabled = v;
    qDebug() << "[TransitionController] fadeInEnabled =" << v;
    emit fadeInEnabledChanged();
}

// ==================== 辅助 ====================

float TransitionController::debugTPFor(const char *name) const
{
    float v = -1.0f;
    if (name == QStringLiteral("cloud"))   v = m_debugCloudTP;
    else if (name == QStringLiteral("weather")) v = m_debugWeatherTP;
    else if (name == QStringLiteral("fog"))     v = m_debugFogTP;
    // 0=自动模式，返回-1表示无覆盖
    return (v > 0.001f) ? v : -1.0f;
}

static const char *nameForSignals(bool cloud, bool weather, bool fog)
{
    if (cloud)   return "cloud";
    if (weather) return "weather";
    if (fog)     return "fog";
    return "?";
}

// ==================== setSkyState ====================

void TransitionController::setSkyState(const SkyState &s)
{
    ++m_transitionId;
    SkyState prev = m_prev;
    m_prev = s;

    const float kActivate   = 0.015f;
    const float kDeactivate = 0.005f;

    // === Cloud ===
    bool cloudNow  = s.cloudCoverage > kActivate;
    bool cloudWas  = prev.cloudCoverage > kDeactivate;
    qDebug() << "[TransitionController] cloud: now=" << cloudNow
             << "was=" << cloudWas << "active=" << m_cloudActive
             << "cov=" << s.cloudCoverage;

    if (cloudNow && !cloudWas) {
        activateLayer(m_cloudTP, m_cloudActive, "cloud", m_transitionId,
                      debugTPFor("cloud"), 600);
    } else if (!cloudNow && cloudWas) {
        deactivateLayer(m_cloudTP, m_cloudActive, "cloud", m_transitionId, 600);
    } else if (cloudNow) {
        if (!m_cloudActive) { m_cloudActive = true; emit cloudActiveChanged(); }
        float d = qAbs(s.cloudCoverage - prev.cloudCoverage);
        if (d > 0.01f) qDebug() << "[TransitionController] cloudCoverage:" << prev.cloudCoverage << "->" << s.cloudCoverage;
    } else {
        if (m_cloudActive) deactivateLayer(m_cloudTP, m_cloudActive, "cloud", m_transitionId, 600);
    }

    // === Weather ===
    float wi = s.rainIntensity + s.snowIntensity;
    float pw = prev.rainIntensity + prev.snowIntensity;
    bool weatherNow  = wi > kActivate;
    bool weatherWas  = pw > kDeactivate;
    qDebug() << "[TransitionController] weather: now=" << weatherNow
             << "was=" << weatherWas << "active=" << m_weatherActive
             << "int=" << wi;

    if (weatherNow && !weatherWas) {
        activateLayer(m_weatherTP, m_weatherActive, "weather", m_transitionId,
                      debugTPFor("weather"), 600);
    } else if (!weatherNow && weatherWas) {
        deactivateLayer(m_weatherTP, m_weatherActive, "weather", m_transitionId, 600);
    } else if (weatherNow) {
        if (!m_weatherActive) { m_weatherActive = true; emit weatherActiveChanged(); }
        float d = qAbs(wi - pw);
        if (d > 0.01f) qDebug() << "[TransitionController] weatherIntensity:" << pw << "->" << wi;
    } else {
        if (m_weatherActive) deactivateLayer(m_weatherTP, m_weatherActive, "weather", m_transitionId, 600);
    }

    // === Fog ===
    bool fogNow = s.fogDensity > kActivate;
    bool fogWas = prev.fogDensity > kDeactivate;
    qDebug() << "[TransitionController] fog: now=" << fogNow
             << "was=" << fogWas << "active=" << m_fogActive
             << "den=" << s.fogDensity;

    if (fogNow && !fogWas) {
        activateLayer(m_fogTP, m_fogActive, "fog", m_transitionId,
                      debugTPFor("fog"), 400);
    } else if (!fogNow && fogWas) {
        deactivateLayer(m_fogTP, m_fogActive, "fog", m_transitionId, 400);
    } else if (fogNow) {
        if (!m_fogActive) { m_fogActive = true; emit fogActiveChanged(); }
    } else {
        if (m_fogActive) deactivateLayer(m_fogTP, m_fogActive, "fog", m_transitionId, 400);
    }

    // === Lightning ===
    bool ln = s.lightningProb > 0.0f;
    if (ln != m_lightningActive) {
        m_lightningActive = ln;
        qDebug() << "[TransitionController] lightning:" << (ln ? "ON" : "OFF");
        emit lightningActiveChanged();
    }
}

// ==================== 激活 ====================

void TransitionController::activateLayer(float &tp, bool &active,
                                          const char *name, int localId,
                                          float debugOverride, float durationMs)
{
    Q_UNUSED(durationMs)
    active = true;

    // 发射 active 信号
    if (name == QStringLiteral("cloud"))   emit cloudActiveChanged();
    else if (name == QStringLiteral("weather")) emit weatherActiveChanged();
    else if (name == QStringLiteral("fog")) emit fogActiveChanged();

    // debug 覆盖
    if (debugOverride >= 0.0f) {
        tp = debugOverride;
        if (name == QStringLiteral("cloud"))   emit cloudTPChanged();
        else if (name == QStringLiteral("weather")) emit weatherTPChanged();
        else if (name == QStringLiteral("fog")) emit fogTPChanged();
        qDebug() << "[TransitionController] activate(" << name
                 << ") active=true, tp=debug(" << debugOverride << ")";
        return;
    }

    if (m_fadeInEnabled) {
        // 渐变：tp 保持当前（0），下一帧设 1 → Behavior 动画 0→1
        qDebug() << "[TransitionController] activate(" << name
                 << ") active=true, tp=0.0 (schedule 1.0 in 16ms fadeIn)";
        int id = localId;
        QTimer::singleShot(16, this, [this, id, &tp, name]() {
            if (m_transitionId != id) {
                qDebug() << "[TransitionController] activate(" << name
                         << ") timer CANCELLED";
                return;
            }
            tp = 1.0f;
            if (name == QStringLiteral("cloud"))   emit cloudTPChanged();
            else if (name == QStringLiteral("weather")) emit weatherTPChanged();
            else if (name == QStringLiteral("fog")) emit fogTPChanged();
            qDebug() << "[TransitionController] activate(" << name
                     << ") timer FIRED → tp=1.0";
        });
    } else {
        // 即时激活
        tp = 1.0f;
        if (name == QStringLiteral("cloud"))   emit cloudTPChanged();
        else if (name == QStringLiteral("weather")) emit weatherTPChanged();
        else if (name == QStringLiteral("fog")) emit fogTPChanged();
        qDebug() << "[TransitionController] activate(" << name
                 << ") active=true, tp=1.0 (instant)";
    }
}

// ==================== 去激活 ====================

void TransitionController::deactivateLayer(float &tp, bool &active,
                                            const char *name, int localId,
                                            float durationMs)
{
    // 先设 tp=0 → Behavior 开始淡出动画
    tp = 0.0f;
    if (name == QStringLiteral("cloud"))   emit cloudTPChanged();
    else if (name == QStringLiteral("weather")) emit weatherTPChanged();
    else if (name == QStringLiteral("fog")) emit fogTPChanged();

    int dur = static_cast<int>(durationMs);
    qDebug() << "[TransitionController] deactivate(" << name
             << ") tp=0, active=true (destroy in" << dur << "ms)";

    // 延迟销毁：等 Behavior 动画播完
    int id = localId;
    QTimer::singleShot(dur, this, [this, id, &active, name]() {
        if (m_transitionId != id) {
            qDebug() << "[TransitionController] deactivate(" << name
                     << ") timer CANCELLED";
            return;
        }
        active = false;
        if (name == QStringLiteral("cloud"))   emit cloudActiveChanged();
        else if (name == QStringLiteral("weather")) emit weatherActiveChanged();
        else if (name == QStringLiteral("fog")) emit fogActiveChanged();
        qDebug() << "[TransitionController] deactivate(" << name
                 << ") timer FIRED → active=false";
    });
}

// ==================== 状态转储 ====================

QString TransitionController::dumpState() const
{
    return QStringLiteral(
        "[TransitionController] cloud: a=%1 tp=%2 dtp=%3 | "
        "weather: a=%4 tp=%5 dtp=%6 | "
        "fog: a=%7 tp=%8 dtp=%9 | "
        "lightning: a=%10 | fadeIn=%11")
        .arg(m_cloudActive).arg(m_cloudTP,0,'f',2).arg(m_debugCloudTP,0,'f',2)
        .arg(m_weatherActive).arg(m_weatherTP,0,'f',2).arg(m_debugWeatherTP,0,'f',2)
        .arg(m_fogActive).arg(m_fogTP,0,'f',2).arg(m_debugFogTP,0,'f',2)
        .arg(m_lightningActive).arg(m_fadeInEnabled);
}
