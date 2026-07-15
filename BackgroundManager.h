#pragma once
#include <QObject>
#include <QTimer>
#include "SkyState.h"
#include "WeatherProfile.h"
#include "AstronomyModel.h"

class TransitionController;

// BackgroundManager: 天空状态管理器
// 职责:
//   1. 接收天气/天文数据 → 更新 SkyState
//   2. Auto/Debug 双模式
//   3. 视差传递
//   4. 天文定时刷新
class BackgroundManager : public QObject {
    Q_OBJECT

    // ===== 输出: SkyState =====
    Q_PROPERTY(SkyState skyState READ skyState NOTIFY skyStateChanged)
    Q_PROPERTY(int controlMode READ controlMode NOTIFY controlModeChanged) // 0=Auto, 1=Debug

public:
    explicit BackgroundManager(QObject *parent = nullptr);

    const SkyState &skyState() const { return m_skyState; }
    int controlMode() const { return m_controlMode; }

    // 关联 TransitionController
    void setTransitionController(TransitionController *ctrl) { m_transitionCtrl = ctrl; }

    // ===== 输入 (供 Main.qml 调用) =====
    Q_INVOKABLE void updateWeather(int iconCode, bool isDay);
    Q_INVOKABLE void updateSunTimes(const QString &sunrise, const QString &sunset);
    Q_INVOKABLE void updateMoonData(int phaseIcon, float illumination);
    Q_INVOKABLE void setLocation(float lat, float lon);
    Q_INVOKABLE void setParallax(float x, float y);

    // ===== Debug (供 DebugPanel 调用) =====
    Q_INVOKABLE void enterDebugMode();
    Q_INVOKABLE void exitDebugMode();
    Q_INVOKABLE void setDebugField(const QString &field, float value);
    Q_INVOKABLE void stepTime(int minutes);      // 冻结时间 + 手动步进
    Q_INVOKABLE void setDebugSkyState(const SkyState &s);

    // 验证
    Q_INVOKABLE QString dumpState() const;

signals:
    void skyStateChanged();
    void controlModeChanged();
    void debugModeEntered();
    void debugModeExited();

private slots:
    void onAstronomyTimer();

private:
    SkyState m_skyState;
    SkyState m_debugSkyState;   // Debug 模式快照
    int m_controlMode = 0;      // 0=Auto, 1=Debug

    WeatherProfileDB m_profiles;
    AstronomyModel m_astronomy;
    TransitionController *m_transitionCtrl = nullptr;
    QTimer m_astronomyTimer;

    void syncAstronomyToSkyState();
    void updateAtmosphere();    // sunProgress → 天空色+曝光+twilight
    static QColor mixColor(const QColor &a, const QColor &b, float t);
};
