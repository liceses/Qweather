#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include "SkyState.h"
#include "WeatherProfile.h"
#include "AstronomyModel.h"

class TransitionController;

// BackgroundManager: 天空状态管理器
// 统一写入路径: commitSkyState(QVariantMap) — 增量合入，只更新 changes 中存在的字段
// Auto 模式: updateWeather / updateSunTimes / updateMoonData 各自构造 changes 调 commitSkyState
// Debug 模式: DebugPanel 构造完整 changes 调 commitSkyState
class BackgroundManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(SkyState skyState READ skyState NOTIFY skyStateChanged)
    Q_PROPERTY(int controlMode READ controlMode NOTIFY controlModeChanged)

public:
    explicit BackgroundManager(QObject *parent = nullptr);

    const SkyState &skyState() const { return m_skyState; }
    int controlMode() const { return m_controlMode; }

    void setTransitionController(TransitionController *ctrl) { m_transitionCtrl = ctrl; }

    // ===== 唯一公共写入入口（QML + C++ 共用）=====
    // 增量合入: changes 中只包含要修改的字段，其余保持当前值
    // Debug 面板传全部字段，Auto 模式各自只传自己的字段
    Q_INVOKABLE void commitSkyState(const QVariantMap &changes);

    // ===== Auto 模式入口 =====
    Q_INVOKABLE void updateWeather(int iconCode, bool isDay);
    Q_INVOKABLE void updateSunTimes(const QString &sunrise, const QString &sunset);
    Q_INVOKABLE void updateMoonData(int phaseIcon, float illumination);
    Q_INVOKABLE void setLocation(float lat, float lon);
    Q_INVOKABLE void setParallax(float x, float y);

    // ===== Debug 模式 =====
    Q_INVOKABLE void enterDebugMode();
    Q_INVOKABLE void exitDebugMode();
    Q_INVOKABLE void setDebugTime(qreal hour);

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
    int m_controlMode = 0;

    WeatherProfileDB m_profiles;
    AstronomyModel m_astronomy;
    TransitionController *m_transitionCtrl = nullptr;
    QTimer m_astronomyTimer;

    // 辅助: 从当前 astronomy 状态构造天文+大气 changes
    QVariantMap buildAstronomyChanges();
    QVariantMap buildAtmosphereChanges();
    static QColor mixColor(const QColor &a, const QColor &b, float t);
    static float clampColor(float value);
};
