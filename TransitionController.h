#pragma once
#include <QObject>
#include "SkyState.h"

// TransitionController — Layer activation/deactivation with tp interpolation
// 图层激活/去激活 + tp 过渡进度控制
// - 迟滞阈值防止振荡切换
// - fadeInEnabled 控制激活时是否渐变（Debug 模式即时，Auto 模式渐变）
// - debug*TP 可覆盖各层 tp 值用于调试
// - 去激活时先设 tp=0 再延迟销毁（确保 Behavior 动画播完才销毁 Loader）
class TransitionController : public QObject {
    Q_OBJECT

    // ===== Layer 活性 =====
    Q_PROPERTY(bool cloudActive     READ cloudActive     NOTIFY cloudActiveChanged)
    Q_PROPERTY(bool weatherActive   READ weatherActive   NOTIFY weatherActiveChanged)
    Q_PROPERTY(bool fogActive       READ fogActive       NOTIFY fogActiveChanged)
    Q_PROPERTY(bool lightningActive READ lightningActive NOTIFY lightningActiveChanged)

    // ===== tp 过渡进度（只读，由 activate/deactivate 管理）=====
    Q_PROPERTY(float cloudTP     READ cloudTP     NOTIFY cloudTPChanged)
    Q_PROPERTY(float weatherTP   READ weatherTP   NOTIFY weatherTPChanged)
    Q_PROPERTY(float fogTP       READ fogTP       NOTIFY fogTPChanged)

    // ===== Debug tp 覆盖（-1 = 不覆盖，≥0 则锁定该层 tp 为指定值）=====
    Q_PROPERTY(float debugCloudTP   READ debugCloudTP   WRITE setDebugCloudTP   NOTIFY debugCloudTPChanged)
    Q_PROPERTY(float debugWeatherTP READ debugWeatherTP WRITE setDebugWeatherTP NOTIFY debugWeatherTPChanged)
    Q_PROPERTY(float debugFogTP     READ debugFogTP     WRITE setDebugFogTP     NOTIFY debugFogTPChanged)

    // ===== 淡入开关（false = 即时激活，true = 渐变激活）=====
    Q_PROPERTY(bool fadeInEnabled READ fadeInEnabled WRITE setFadeInEnabled NOTIFY fadeInEnabledChanged)

public:
    explicit TransitionController(QObject *parent = nullptr);

    // Layer activity accessors / 图层活性访问器
    bool cloudActive()     const { return m_cloudActive; }
    bool weatherActive()   const { return m_weatherActive; }
    bool fogActive()       const { return m_fogActive; }
    bool lightningActive() const { return m_lightningActive; }

    // Transition progress (tp) accessors / 过渡进度访问器
    float cloudTP()     const { return m_cloudTP; }
    float weatherTP()   const { return m_weatherTP; }
    float fogTP()       const { return m_fogTP; }

    // Debug tp override (≥0 overrides the layer tp to this value) / 调试 tp 覆盖（≥0 则锁定该层 tp）
    float debugCloudTP()   const { return m_debugCloudTP; }
    float debugWeatherTP() const { return m_debugWeatherTP; }
    float debugFogTP()     const { return m_debugFogTP; }
    void setDebugCloudTP(float v);
    void setDebugWeatherTP(float v);
    void setDebugFogTP(float v);

    // Fade-in toggle: false = instant activation, true = fade-in / 淡入开关：false=即时激活，true=渐变激活
    bool fadeInEnabled() const { return m_fadeInEnabled; }
    void setFadeInEnabled(bool v);

    // setSkyState — Called by BackgroundManager on commitSkyState / 由 BackgroundManager 在 commitSkyState 时调用
    void setSkyState(const SkyState &newState);

    // dumpState — Debug dump of all layer states / 调试输出所有图层状态
    Q_INVOKABLE QString dumpState() const;

signals:
    void cloudActiveChanged();
    void weatherActiveChanged();
    void fogActiveChanged();
    void lightningActiveChanged();
    void cloudTPChanged();
    void weatherTPChanged();
    void fogTPChanged();
    void debugCloudTPChanged();
    void debugWeatherTPChanged();
    void debugFogTPChanged();
    void fadeInEnabledChanged();

private:
    // Current layer state / 当前图层状态
    SkyState m_prev;                                              // Previous SkyState for transition detection / 上一帧的天空状态
    bool m_cloudActive = false, m_weatherActive = false;          // Cloud / weather layer active / 云/天气层是否激活
    bool m_fogActive = false, m_lightningActive = false;          // Fog / lightning layer active / 雾/闪电层是否激活
    float m_cloudTP = 0.0f, m_weatherTP = 0.0f, m_fogTP = 0.0f;  // Transition progress 0–1 / 过渡进度

    // Debug overrides (0=auto, >0=manual) / 调试覆盖值（0=自动，>0=手动控制）
    float m_debugCloudTP = 0.0f, m_debugWeatherTP = 0.0f, m_debugFogTP = 0.0f;
    bool m_fadeInEnabled = true;        // Fade-in enabled flag / 淡入启用标志

    // Debounce: incremented on each setSkyState, captured by timer lambda / 防抖：每次 setSkyState 递增，timer lambda 捕获判断
    int m_transitionId = 0;

    // Internal methods with localId debounce / 内部方法，带 localId 防抖
    void activateLayer(float &tp, bool &active, const char *name, int localId,
                       float debugOverride, float delayMs);
    void deactivateLayer(float &tp, bool &active, const char *name, int localId,
                         float durationMs);

    // debugTPFor — Get debug tp override for a layer (-1 = no override) / 获取某层调试 tp 覆盖值（-1 = 无覆盖）
    float debugTPFor(const char *name) const;
};
