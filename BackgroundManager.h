#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include "SkyState.h"
#include "WeatherProfile.h"
#include "AstronomyModel.h"

class TransitionController;

// BackgroundManager — Central orchestrator for sky + weather rendering
// 背景管理器，协调天文、天气、大气状态，驱动 SkyLayer 实时渲染
class BackgroundManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(SkyState skyState READ skyState NOTIFY skyStateChanged)
    Q_PROPERTY(int controlMode READ controlMode NOTIFY controlModeChanged)

public:
    explicit BackgroundManager(QObject *parent = nullptr);

    // skyState — Current combined rendering state / 当前合并渲染状态
    const SkyState &skyState() const { return m_skyState; }
    // controlMode — 0=auto, 1=debug / 控制模式：0=自动, 1=调试
    int controlMode() const { return m_controlMode; }

    // setTransitionController — Inject transition controller / 注入过渡控制器
    void setTransitionController(TransitionController *ctrl) { m_transitionCtrl = ctrl; }

    // commitSkyState — Apply partial state changes from QML / 从 QML 应用部分状态变更
    Q_INVOKABLE void commitSkyState(const QVariantMap &changes);

    // Weather / astronomy update entry points / 天气/天文更新入口
    Q_INVOKABLE void updateWeather(int iconCode, bool isDay);
    Q_INVOKABLE void updateSunTimes(const QString &sunrise, const QString &sunset);
    Q_INVOKABLE void updateMoonData(int phaseIcon, float illumination);
    Q_INVOKABLE void setLocation(float lat, float lon);
    // setParallax — Device tilt parallax offset / 设备倾斜视差偏移
    Q_INVOKABLE void setParallax(float x, float y);

    // Debug mode controls / 调试模式控制
    Q_INVOKABLE void enterDebugMode();
    Q_INVOKABLE void exitDebugMode();
    Q_INVOKABLE void setDebugTime(qreal hour);

    // dumpState — Debug state string / 调试状态字符串输出
    Q_INVOKABLE QString dumpState() const;

    Q_PROPERTY(int currentWeatherCode READ currentWeatherCode NOTIFY currentWeatherChanged)
    Q_PROPERTY(bool currentIsDay READ currentIsDay NOTIFY currentWeatherChanged)
    int currentWeatherCode() const { return m_currentWeatherCode; }
    bool currentIsDay() const { return m_currentIsDay; }

    // currentLocalTime — Formatted HH:mm from astronomy model / 从天体模型格式化的 HH:mm 本地时间
    Q_PROPERTY(QString currentLocalTime READ currentLocalTime NOTIFY skyStateChanged)
    QString currentLocalTime() const {
        int min = m_astronomy.currentMin();
        int h = min / 60, m = min % 60;
        return QString("%1:%2")
            .arg(h, 2, 10, QLatin1Char('0'))
            .arg(m, 2, 10, QLatin1Char('0'));
    }

    // configPath — Path to weather profile config file / 天气配置文件的路径
    Q_PROPERTY(QString configPath READ configPath CONSTANT)
    QString configPath() const { return m_configPath; }
    // saveProfileForCode — Persist current profile for a weather code / 持久化当前天气码的配置
    Q_INVOKABLE void saveProfileForCode(int code);

signals:
    void skyStateChanged();
    void controlModeChanged();
    void debugModeEntered();
    void debugModeExited();
    void currentWeatherChanged();

private slots:
    void onAstronomyTimer();
    void tickLerp();

private:
    QTimer m_lerpTimer;                      // Timer driving lerp animation / 驱动线性插值动画的计时器
    float m_lerpFrom[6] = {};                // Lerp start values / 插值起始值数组
    float m_lerpTo[6] = {};                  // Lerp end values / 插值目标值数组
    int m_lerpTick = 0;                      // Current lerp tick count / 当前插值帧计数
    static constexpr int LERP_DURATION = 60; // Total lerp duration in ticks / 总插值帧数（≈1秒）

    SkyState m_skyState;          // Current rendered sky state / 当前渲染的天空状态
    int m_controlMode = 0;         // 0=auto, 1=debug / 控制模式

    WeatherProfileDB m_profiles;   // Weather profile database / 天气配置数据库
    QString m_configPath;          // Path to profile JSON config / 配置文件路径
    int m_currentWeatherCode = 100; // Last applied weather icon code / 最近应用的天气图标码
    bool m_currentIsDay = true;     // Whether current time is day / 当前是否为白天
    AstronomyModel m_astronomy;     // Astronomy calculation model / 天文计算模型
    TransitionController *m_transitionCtrl = nullptr; // Injected transition controller / 注入的过渡控制器
    QTimer m_astronomyTimer;       // Timer for astronomy updates / 天文更新定时器
    float m_lastWeatherScale = 1.0f; // Last weather intensity scale / 最近天气强度缩放因子

    // buildAstronomyChanges / buildAtmosphereChanges — Construct partial state diffs / 构建部分状态变更集
    QVariantMap buildAstronomyChanges();
    QVariantMap buildAtmosphereChanges();
    // mixColor — Linear interpolation between two QColors / 两个 QColor 之间的线性插值
    static QColor mixColor(const QColor &a, const QColor &b, float t);
    // clampColor — Clamp float to [0,1] range / 将浮点数限制到 [0,1] 范围
    static float clampColor(float value);
};
