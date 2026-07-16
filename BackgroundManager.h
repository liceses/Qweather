#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include "SkyState.h"
#include "WeatherProfile.h"
#include "AstronomyModel.h"

class TransitionController;

class BackgroundManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(SkyState skyState READ skyState NOTIFY skyStateChanged)
    Q_PROPERTY(int controlMode READ controlMode NOTIFY controlModeChanged)

public:
    explicit BackgroundManager(QObject *parent = nullptr);

    const SkyState &skyState() const { return m_skyState; }
    int controlMode() const { return m_controlMode; }

    void setTransitionController(TransitionController *ctrl) { m_transitionCtrl = ctrl; }

    Q_INVOKABLE void commitSkyState(const QVariantMap &changes);

    Q_INVOKABLE void updateWeather(int iconCode, bool isDay);
    Q_INVOKABLE void updateSunTimes(const QString &sunrise, const QString &sunset);
    Q_INVOKABLE void updateMoonData(int phaseIcon, float illumination);
    Q_INVOKABLE void setLocation(float lat, float lon);
    Q_INVOKABLE void setParallax(float x, float y);

    Q_INVOKABLE void enterDebugMode();
    Q_INVOKABLE void exitDebugMode();
    Q_INVOKABLE void setDebugTime(qreal hour);

    Q_INVOKABLE QString dumpState() const;

    Q_PROPERTY(int currentWeatherCode READ currentWeatherCode NOTIFY currentWeatherChanged)
    Q_PROPERTY(bool currentIsDay READ currentIsDay NOTIFY currentWeatherChanged)
    int currentWeatherCode() const { return m_currentWeatherCode; }
    bool currentIsDay() const { return m_currentIsDay; }

    Q_PROPERTY(QString currentLocalTime READ currentLocalTime NOTIFY skyStateChanged)
    QString currentLocalTime() const {
        int min = m_astronomy.currentMin();
        int h = min / 60, m = min % 60;
        return QString("%1:%2")
            .arg(h, 2, 10, QLatin1Char('0'))
            .arg(m, 2, 10, QLatin1Char('0'));
    }

    Q_PROPERTY(QString configPath READ configPath CONSTANT)
    QString configPath() const { return m_configPath; }
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
    QTimer m_lerpTimer;
    float m_lerpFrom[6] = {};
    float m_lerpTo[6] = {};
    int m_lerpTick = 0;
    static constexpr int LERP_DURATION = 60;

    SkyState m_skyState;
    int m_controlMode = 0;

    WeatherProfileDB m_profiles;
    QString m_configPath;
    int m_currentWeatherCode = 100;
    bool m_currentIsDay = true;
    AstronomyModel m_astronomy;
    TransitionController *m_transitionCtrl = nullptr;
    QTimer m_astronomyTimer;
    float m_lastWeatherScale = 1.0f;

    QVariantMap buildAstronomyChanges();
    QVariantMap buildAtmosphereChanges();
    static QColor mixColor(const QColor &a, const QColor &b, float t);
    static float clampColor(float value);
};
