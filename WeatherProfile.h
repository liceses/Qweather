#pragma once
#include <QString>
#include <QHash>
#include <QJsonObject>

struct WeatherProfile {
    QString weatherParticle;
    float intensity = 0.0f;
    int weatherVariant = 0;
    bool cloudActive = false;
    float cloudCoverage = 0.0f;
    int cloudVariant = 0;
    bool fogActive = false;
    float fogIntensity = 0.0f;
    int fogVariant = 0;
    bool lightningActive = false;
    float exposureOffset = 0.0f;  // -1~1 叠加到 S 曲线调制后的曝光

    QJsonObject toJson() const;
    static WeatherProfile fromJson(const QJsonObject &o);
};

class WeatherProfileDB {
public:
    WeatherProfileDB();
    WeatherProfile fromCode(int iconCode, bool isDay) const;
    void dumpRegisteredCodes() const;

    void loadFromFile(const QString &path);
    void saveToFile(const QString &path) const;

    const QHash<int, WeatherProfile> &dayProfiles() const { return m_dayProfiles; }
    const QHash<int, WeatherProfile> &nightOverrides() const { return m_nightOverrides; }

    // 写入（供调试调校保存）
    void setDayProfile(int code, const WeatherProfile &p) { m_dayProfiles[code] = p; }
    void setNightOverride(int code, const WeatherProfile &p) { m_nightOverrides[code] = p; }

private:
    QHash<int, WeatherProfile> m_dayProfiles;
    QHash<int, WeatherProfile> m_nightOverrides;
    void initProfiles();
};
