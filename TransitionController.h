#pragma once
#include <QObject>
#include "SkyState.h"

// TransitionController: Layer 激活/去激活
// 比较新旧 SkyState → 控制各 Layer 的 active 和 transitionProgress
class TransitionController : public QObject {
    Q_OBJECT

    // ===== QML 绑定: 控制 Layer Loader.active =====
    Q_PROPERTY(bool cloudActive     READ cloudActive     NOTIFY cloudActiveChanged)
    Q_PROPERTY(bool weatherActive   READ weatherActive   NOTIFY weatherActiveChanged)
    Q_PROPERTY(bool fogActive       READ fogActive       NOTIFY fogActiveChanged)
    Q_PROPERTY(bool lightningActive READ lightningActive NOTIFY lightningActiveChanged)

    // ===== QML 绑定: 驱动 Layer transitionProgress =====
    Q_PROPERTY(float cloudTP     READ cloudTP     NOTIFY cloudTPChanged)
    Q_PROPERTY(float weatherTP   READ weatherTP   NOTIFY weatherTPChanged)
    Q_PROPERTY(float fogTP       READ fogTP       NOTIFY fogTPChanged)

public:
    explicit TransitionController(QObject *parent = nullptr);

    bool cloudActive()     const { return m_cloudActive; }
    bool weatherActive()   const { return m_weatherActive; }
    bool fogActive()       const { return m_fogActive; }
    bool lightningActive() const { return m_lightningActive; }

    float cloudTP()     const { return m_cloudTP; }
    float weatherTP()   const { return m_weatherTP; }
    float fogTP()       const { return m_fogTP; }

    void setSkyState(const SkyState &newState);

    Q_INVOKABLE QString dumpState() const;

signals:
    void cloudActiveChanged();
    void weatherActiveChanged();
    void fogActiveChanged();
    void lightningActiveChanged();
    void cloudTPChanged();
    void weatherTPChanged();
    void fogTPChanged();

private:
    SkyState m_prev;
    bool m_cloudActive = false;
    bool m_weatherActive = false;
    bool m_fogActive = false;
    bool m_lightningActive = false;
    float m_cloudTP = 0.0f;
    float m_weatherTP = 0.0f;
    float m_fogTP = 0.0f;

    float m_lastCloudCov = 0.0f;
    float m_lastRainInt = 0.0f;
    float m_lastSnowInt = 0.0f;
    float m_lastFogDen = 0.0f;
    float m_lastLightning = 0.0f;

    void activateLayer(float &tp, bool &active, const char *name);
    void deactivateLayer(float &tp, bool &active, const char *name);
};
