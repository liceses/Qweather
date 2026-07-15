#include "TransitionController.h"
#include <QDebug>
#include <QtMath>

TransitionController::TransitionController(QObject *parent)
    : QObject(parent)
{
    qDebug() << "[TransitionController] created, all layers inactive";
}

void TransitionController::setSkyState(const SkyState &s)
{
    SkyState prev = m_prev;
    m_prev = s;

    // === Cloud ===
    bool cloudNow = s.cloudCoverage > 0.01f;
    bool cloudWas = prev.cloudCoverage > 0.01f;

    if (cloudNow && !cloudWas) {
        // 云激活（立即，无防抖）
        activateLayer(m_cloudTP, m_cloudActive, "cloud");
    } else if (!cloudNow && cloudWas) {
        deactivateLayer(m_cloudTP, m_cloudActive, "cloud");
    } else if (cloudNow) {
        // 已在激活状态，确保 active=true
        if (!m_cloudActive) {
            m_cloudActive = true;
            emit cloudActiveChanged();
        }
        m_cloudTP = 1.0f;
        emit cloudTPChanged();
        float diff = qAbs(s.cloudCoverage - prev.cloudCoverage);
        if (diff > 0.01f) {
            qDebug() << "[TransitionController] cloudCoverage changed:"
                     << prev.cloudCoverage << "->" << s.cloudCoverage;
        }
    } else {
        // 未激活且不需要激活，确保 inactive
        if (m_cloudActive) {
            deactivateLayer(m_cloudTP, m_cloudActive, "cloud");
        }
    }

    // === Weather (Rain + Snow) ===
    float weatherIntensity = s.rainIntensity + s.snowIntensity;
    float prevWeatherIntensity = prev.rainIntensity + prev.snowIntensity;
    bool weatherNow = weatherIntensity > 0.001f;
    bool weatherWas = prevWeatherIntensity > 0.001f;

    if (weatherNow && !weatherWas) {
        activateLayer(m_weatherTP, m_weatherActive, "weather");
    } else if (!weatherNow && weatherWas) {
        deactivateLayer(m_weatherTP, m_weatherActive, "weather");
    } else if (weatherNow) {
        if (!m_weatherActive) {
            m_weatherActive = true;
            emit weatherActiveChanged();
        }
        m_weatherTP = 1.0f;
        emit weatherTPChanged();
        float diff = qAbs(weatherIntensity - prevWeatherIntensity);
        if (diff > 0.01f) {
            qDebug() << "[TransitionController] weatherIntensity changed:"
                     << prevWeatherIntensity << "->" << weatherIntensity;
        }
    } else {
        if (m_weatherActive) {
            deactivateLayer(m_weatherTP, m_weatherActive, "weather");
        }
    }

    // === Fog ===
    bool fogNow = s.fogDensity > 0.001f;
    bool fogWas = prev.fogDensity > 0.001f;

    if (fogNow && !fogWas) {
        activateLayer(m_fogTP, m_fogActive, "fog");
    } else if (!fogNow && fogWas) {
        deactivateLayer(m_fogTP, m_fogActive, "fog");
    } else if (fogNow) {
        if (!m_fogActive) {
            m_fogActive = true;
            emit fogActiveChanged();
        }
        m_fogTP = 1.0f;
        emit fogTPChanged();
    } else {
        if (m_fogActive) {
            deactivateLayer(m_fogTP, m_fogActive, "fog");
        }
    }

    // === Lightning ===
    bool lightningNow = s.lightningProb > 0.0f;
    if (lightningNow != m_lightningActive) {
        m_lightningActive = lightningNow;
        qDebug() << "[TransitionController] lightningActive:" << lightningNow;
        emit lightningActiveChanged();
    }

    m_lastCloudCov = s.cloudCoverage;
    m_lastRainInt = s.rainIntensity;
    m_lastSnowInt = s.snowIntensity;
    m_lastFogDen = s.fogDensity;
    m_lastLightning = s.lightningProb;
}

void TransitionController::activateLayer(float &tp, bool &active, const char *name)
{
    active = true;
    tp = 1.0f;

    qDebug() << "[TransitionController] activate(" << name << ") active=true, tp=1.0";

    if (name == QString("cloud")) {
        emit cloudActiveChanged();
        emit cloudTPChanged();
    } else if (name == QString("weather")) {
        emit weatherActiveChanged();
        emit weatherTPChanged();
    } else if (name == QString("fog")) {
        emit fogActiveChanged();
        emit fogTPChanged();
    }
}

void TransitionController::deactivateLayer(float &tp, bool &active, const char *name)
{
    active = false;
    tp = 0.0f;

    qDebug() << "[TransitionController] deactivate(" << name << ") active=false, tp=0.0";

    if (name == QString("cloud")) {
        emit cloudActiveChanged();
        emit cloudTPChanged();
    } else if (name == QString("weather")) {
        emit weatherActiveChanged();
        emit weatherTPChanged();
    } else if (name == QString("fog")) {
        emit fogActiveChanged();
        emit fogTPChanged();
    }
}

QString TransitionController::dumpState() const
{
    return QStringLiteral(
        "[TransitionController] cloud: active=%1 tp=%2 | weather: active=%3 tp=%4 | "
        "fog: active=%5 tp=%6 | lightning: active=%7")
        .arg(m_cloudActive).arg(m_cloudTP, 0, 'f', 2)
        .arg(m_weatherActive).arg(m_weatherTP, 0, 'f', 2)
        .arg(m_fogActive).arg(m_fogTP, 0, 'f', 2)
        .arg(m_lightningActive);
}
