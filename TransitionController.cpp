#include "TransitionController.h"
#include <QDebug>
#include <QtMath>
#include <QTimer>

// TransitionController constructor / 过渡控制器构造函数
TransitionController::TransitionController(QObject *parent)
    : QObject(parent)
{
    qDebug() << "[TransitionController] created, all layers inactive";
}

// ==================== Debug TP overrides / 调试过渡进度覆盖 ====================

// Debug override for cloud transition progress / 云过渡进度的调试覆盖
void TransitionController::setDebugCloudTP(float v)
{
    v = qBound(0.0f, v, 1.0f);
    if (qFuzzyCompare(m_debugCloudTP, v)) return;
    m_debugCloudTP = v;
    if (v > 0.001f) {
        m_cloudTP = v;
        emit cloudTPChanged();
    } else if (m_cloudActive) {
        m_cloudTP = 1.0f;                            // Reset to full when debug released / 释放调试后重置为全开
        emit cloudTPChanged();
    }
    qDebug() << "[TransitionController] debugCloudTP =" << v;
    emit debugCloudTPChanged();
}

// Debug override for weather transition progress / 天气过渡进度的调试覆盖
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

// Debug override for fog transition progress / 雾过渡进度的调试覆盖
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

// Enable/disable fade-in animation / 启用/禁用淡入动画
void TransitionController::setFadeInEnabled(bool v)
{
    if (m_fadeInEnabled == v) return;
    m_fadeInEnabled = v;
    qDebug() << "[TransitionController] fadeInEnabled =" << v;
    emit fadeInEnabledChanged();
}

// ==================== Helpers / 辅助方法 ====================

// Query debug TP for a layer; returns -1 if no override / 查询层的调试TP；无覆盖时返回-1
float TransitionController::debugTPFor(const char *name) const
{
    float v = -1.0f;
    if (name == QStringLiteral("cloud"))   v = m_debugCloudTP;
    else if (name == QStringLiteral("weather")) v = m_debugWeatherTP;
    else if (name == QStringLiteral("fog"))     v = m_debugFogTP;
    return (v > 0.001f) ? v : -1.0f;            // 0 = auto mode, return -1 = no override / 0=自动模式，返回-1=无覆盖
}

static const char *nameForSignals(bool cloud, bool weather, bool fog)
{
    if (cloud)   return "cloud";
    if (weather) return "weather";
    if (fog)     return "fog";
    return "?";
}

// ==================== setSkyState: main entry to update all layers / 更新所有图层的主入口 ====================

// Main entry: evaluate thresholds and activate/deactivate each layer / 主入口：评估阈值并激活/关闭每个图层
void TransitionController::setSkyState(const SkyState &s)
{
    ++m_transitionId;                              // Increment ID to cancel stale timers / 递增ID以取消过期定时器
    SkyState prev = m_prev;
    m_prev = s;

    const float kActivate   = 0.015f;              // Threshold to activate / 激活阈值
    const float kDeactivate = 0.005f;              // Threshold to deactivate / 去激活阈值

    // === Cloud layer / 云层 ===
    bool cloudNow  = s.cloudCoverage > kActivate;
    bool cloudWas  = prev.cloudCoverage > kDeactivate;
    qDebug() << "[TransitionController] cloud: now=" << cloudNow
             << "was=" << cloudWas << "active=" << m_cloudActive
             << "cov=" << s.cloudCoverage;

    if (cloudNow && !cloudWas) {
        activateLayer(m_cloudTP, m_cloudActive, "cloud", m_transitionId,
                      debugTPFor("cloud"), 100);
    } else if (!cloudNow && cloudWas) {
        deactivateLayer(m_cloudTP, m_cloudActive, "cloud", m_transitionId, 600);
    } else if (cloudNow) {
        if (!m_cloudActive) { m_cloudActive = true; emit cloudActiveChanged(); }
        // Auto mode: ensure tp=1.0 (prevent delay timer from being cancelled by slider) / 自动模式：确保 tp=1.0
        if (debugTPFor("cloud") < 0 && m_cloudTP < 0.99f) {
            m_cloudTP = 1.0f; emit cloudTPChanged();
        }
        float d = qAbs(s.cloudCoverage - prev.cloudCoverage);
        if (d > 0.01f) qDebug() << "[TransitionController] cloudCoverage:" << prev.cloudCoverage << "->" << s.cloudCoverage;
    } else {
        if (m_cloudActive) deactivateLayer(m_cloudTP, m_cloudActive, "cloud", m_transitionId, 600);
    }

    // === Weather layer / 天气层 ===
    float wi = s.rainIntensity + s.snowIntensity;
    float pw = prev.rainIntensity + prev.snowIntensity;
    bool weatherNow  = wi > kActivate;
    bool weatherWas  = pw > kDeactivate;
    qDebug() << "[TransitionController] weather: now=" << weatherNow
             << "was=" << weatherWas << "active=" << m_weatherActive
             << "int=" << wi;

    if (weatherNow && !weatherWas) {
        int wDelay = cloudNow ? 400 : 100;          // Longer delay if cloud is already fading in / 如果云已在淡入则延迟更长
        activateLayer(m_weatherTP, m_weatherActive, "weather", m_transitionId,
                      debugTPFor("weather"), wDelay);
    } else if (!weatherNow && weatherWas) {
        deactivateLayer(m_weatherTP, m_weatherActive, "weather", m_transitionId, 600);
    } else if (weatherNow) {
        if (!m_weatherActive) { m_weatherActive = true; emit weatherActiveChanged(); }
        if (debugTPFor("weather") < 0 && m_weatherTP < 0.99f) {
            m_weatherTP = 1.0f; emit weatherTPChanged();
        }
        float d = qAbs(wi - pw);
        if (d > 0.01f) qDebug() << "[TransitionController] weatherIntensity:" << pw << "->" << wi;
    } else {
        if (m_weatherActive) deactivateLayer(m_weatherTP, m_weatherActive, "weather", m_transitionId, 600);
    }

    // === Fog layer / 雾层 ===
    bool fogNow = s.fogDensity > kActivate;
    bool fogWas = prev.fogDensity > kDeactivate;
    qDebug() << "[TransitionController] fog: now=" << fogNow
             << "was=" << fogWas << "active=" << m_fogActive
             << "den=" << s.fogDensity;

    if (fogNow && !fogWas) {
        activateLayer(m_fogTP, m_fogActive, "fog", m_transitionId,
                      debugTPFor("fog"), 100);
    } else if (!fogNow && fogWas) {
        deactivateLayer(m_fogTP, m_fogActive, "fog", m_transitionId, 400);
    } else if (fogNow) {
        if (!m_fogActive) { m_fogActive = true; emit fogActiveChanged(); }
        if (debugTPFor("fog") < 0 && m_fogTP < 0.99f) {
            m_fogTP = 1.0f; emit fogTPChanged();
        }
    } else {
        if (m_fogActive) deactivateLayer(m_fogTP, m_fogActive, "fog", m_transitionId, 400);
    }

    // === Lightning toggle / 闪电开关 ===
    bool ln = s.lightningProb > 0.0f;
    if (ln != m_lightningActive) {
        m_lightningActive = ln;
        qDebug() << "[TransitionController] lightning:" << (ln ? "ON" : "OFF");
        emit lightningActiveChanged();
    }
}

// ==================== Activate layer / 激活图层 ====================

// Activate a visual layer with optional delay and fade-in / 激活一个视觉效果层，支持可选延迟和淡入
void TransitionController::activateLayer(float &tp, bool &active,
                                          const char *name, int localId,
                                          float debugOverride, float delayMs)
{
    // Debug override: always instant / 调试覆盖：始终即时
    if (debugOverride >= 0.0f) {
        active = true;
        if (name == QStringLiteral("cloud"))   emit cloudActiveChanged();
        else if (name == QStringLiteral("weather")) emit weatherActiveChanged();
        else if (name == QStringLiteral("fog")) emit fogActiveChanged();
        tp = debugOverride;
        if (name == QStringLiteral("cloud"))   emit cloudTPChanged();
        else if (name == QStringLiteral("weather")) emit weatherTPChanged();
        else if (name == QStringLiteral("fog")) emit fogTPChanged();
        qDebug() << "[TransitionController] activate(" << name
                 << ") active=true, tp=debug(" << debugOverride << ")";
        return;
    }

    int dly = m_fadeInEnabled ? static_cast<int>(delayMs) : 0;

    // Instant: no timer needed / 完全即时，无需定时器
    if (dly <= 0 && !m_fadeInEnabled) {
        active = true;
        tp = 1.0f;
        if (name == QStringLiteral("cloud"))   { emit cloudActiveChanged(); emit cloudTPChanged(); }
        else if (name == QStringLiteral("weather")) { emit weatherActiveChanged(); emit weatherTPChanged(); }
        else if (name == QStringLiteral("fog")) { emit fogActiveChanged(); emit fogTPChanged(); }
        qDebug() << "[TransitionController] activate(" << name
                 << ") active=true, tp=1.0 (instant)";
        return;
    }

    // Delayed activation via QTimer / 通过 QTimer 延迟激活
    int id = localId;
    QTimer::singleShot(dly, this, [this, id, dly, &tp, &active, name]() {
        if (m_transitionId != id) {
            qDebug() << "[TransitionController] activate(" << name
                     << ") delay CANCELLED";
            return;                                  // Stale timer / 过期定时器
        }
        active = true;
        if (name == QStringLiteral("cloud"))   emit cloudActiveChanged();
        else if (name == QStringLiteral("weather")) emit weatherActiveChanged();
        else if (name == QStringLiteral("fog")) emit fogActiveChanged();

        if (m_fadeInEnabled) {
            // Fade-in: set tp=0 (component created), then set tp=1.0 one frame later for Behavior animation
            // 渐变：先设tp=0（组件已创建），再等一帧设1.0触发Behavior动画
            qDebug() << "[TransitionController] activate(" << name
                     << ") active=true, schedule tp=1.0";
            int id2 = m_transitionId;
            QTimer::singleShot(16, this, [this, id2, &tp, name]() {
                if (m_transitionId != id2) {
                    qDebug() << "[TransitionController] activate(" << name
                             << ") tp timer CANCELLED";
                    return;
                }
                tp = 1.0f;
                if (name == QStringLiteral("cloud"))   emit cloudTPChanged();
                else if (name == QStringLiteral("weather")) emit weatherTPChanged();
                else if (name == QStringLiteral("fog")) emit fogTPChanged();
                qDebug() << "[TransitionController] activate(" << name
                 << ") tp timer FIRED → tp=1.0";
            });
        } else {
            // Instant set after delay / 延迟后即时设置
            tp = 1.0f;
            if (name == QStringLiteral("cloud"))   emit cloudTPChanged();
            else if (name == QStringLiteral("weather")) emit weatherTPChanged();
            else if (name == QStringLiteral("fog")) emit fogTPChanged();
            qDebug() << "[TransitionController] activate(" << name
                     << ") tp=1.0 (delayed " << dly << "ms)";
        }
    });
}

// ==================== Deactivate layer / 关闭图层 ====================

// Deactivate layer: fade out then destroy after delay / 关闭图层：淡出然后延迟销毁
void TransitionController::deactivateLayer(float &tp, bool &active,
                                            const char *name, int localId,
                                            float durationMs)
{
    tp = 0.0f;                                       // Start fade-out via Behavior animation / 触发Behavior淡出动画
    if (name == QStringLiteral("cloud"))   emit cloudTPChanged();
    else if (name == QStringLiteral("weather")) emit weatherTPChanged();
    else if (name == QStringLiteral("fog")) emit fogTPChanged();

    int dur = static_cast<int>(durationMs);
    qDebug() << "[TransitionController] deactivate(" << name
             << ") tp=0, active=true (destroy in" << dur << "ms)";

    // Delayed destroy: wait for Behavior animation to finish / 延迟销毁：等待Behavior动画播完
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

// ==================== State dump / 状态转储 ====================

// Debug dump of all layer states / 调试：所有图层状态转储
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
