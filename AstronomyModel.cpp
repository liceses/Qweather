#include "AstronomyModel.h"
#include <QDebug>
#include <QtMath>
#include <QTime>

AstronomyModel::AstronomyModel(QObject *parent)
    : QObject(parent)
{
    qDebug() << "[AstronomyModel] created, default location: lat=" << m_lat << "lon=" << m_lon;
}

void AstronomyModel::setLocation(float lat, float lon)
{
    m_lat = lat;
    m_lon = lon;
    qDebug() << "[AstronomyModel] setLocation: lat=" << lat << "lon=" << lon;
}

void AstronomyModel::setSunTimes(const QString &sunrise, const QString &sunset)
{
    auto toMinutes = [](const QString &t) -> int {
        QDateTime dt = QDateTime::fromString(t, Qt::ISODate);
        if (dt.isValid())
            return dt.time().hour() * 60 + dt.time().minute();
        auto parts = t.split(':');
        if (parts.size() >= 2)
            return parts[0].toInt() * 60 + parts[1].toInt();
        return 360;
    };

    m_sunriseMin = toMinutes(sunrise);
    m_sunsetMin  = toMinutes(sunset);
    qDebug() << "[AstronomyModel] sunTimes: sunrise=" << sunrise
             << "(" << m_sunriseMin << "min)"
             << "sunset=" << sunset
             << "(" << m_sunsetMin << "min)";
}

void AstronomyModel::setMoonData(int phaseIcon, float illumination)
{
    m_moonPhase = static_cast<float>(phaseIcon);
    m_moonIllum = illumination;
    qDebug() << "[AstronomyModel] moonData: phaseIcon=" << phaseIcon
             << "illumination=" << illumination;
}

void AstronomyModel::update(qint64 nowMsecs)
{
    QDateTime dt = QDateTime::fromMSecsSinceEpoch(nowMsecs);
    m_dayOfYear = dt.date().dayOfYear();
    int minuteOfDay = dt.time().hour() * 60 + dt.time().minute();
    m_currentMin = minuteOfDay;

    calcSolarPosition(m_dayOfYear, minuteOfDay);

    // 简化月亮位置：取太阳对跖点偏移
    float oppositeAlt = -m_solarAltitude;
    float oppositeAz  = fmod(m_solarAzimuth + 180.0f, 360.0f);
    m_moonAltitude = qBound(-90.0f, oppositeAlt + 15.0f, 90.0f);
    m_moonAzimuth  = oppositeAz;

    qDebug() << "[AstronomyModel] update: dayOfYear=" << m_dayOfYear
             << "minute=" << minuteOfDay
             << "sp=" << sunProgress() << "dp=" << dayProgress()
             << "solarAlt=" << m_solarAltitude
             << "solarAz=" << m_solarAzimuth;

    emit updated();
}

void AstronomyModel::updateByMinute(int minuteOfDay)
{
    minuteOfDay = qBound(0, minuteOfDay, 1440);
    m_currentMin = minuteOfDay;

    calcSolarPosition(m_dayOfYear, minuteOfDay);

    // 月亮位置
    float oppositeAlt = -m_solarAltitude;
    float oppositeAz  = fmod(m_solarAzimuth + 180.0f, 360.0f);
    m_moonAltitude = qBound(-90.0f, oppositeAlt + 15.0f, 90.0f);
    m_moonAzimuth  = oppositeAz;

    int h = minuteOfDay / 60;
    int m = minuteOfDay % 60;
    qDebug() << "[AstronomyModel] updateByMinute: minute=" << minuteOfDay
             << "time=" << h << ":" << m
             << "sp=" << sunProgress() << "dp=" << dayProgress()
             << "solarAlt=" << m_solarAltitude << "solarAz=" << m_solarAzimuth;

    emit updated();
}

void AstronomyModel::calcSolarPosition(int dayOfYear, int minuteOfDay)
{
    // 简化天文公式
    // 太阳赤纬: 23.45° * sin(2π*(dayOfYear-81)/365)
    double declination = 23.45 * qSin(2.0 * M_PI * (dayOfYear - 81) / 365.0);

    // 时角: (当前时间 - 正午) * 15°/小时
    double hourAngle = (minuteOfDay - 720) * 0.25; // 度

    double latRad = qDegreesToRadians(static_cast<double>(m_lat));
    double declRad = qDegreesToRadians(declination);
    double haRad = qDegreesToRadians(hourAngle);

    // 太阳高度角
    double sinAlt = qSin(latRad) * qSin(declRad)
                  + qCos(latRad) * qCos(declRad) * qCos(haRad);
    m_solarAltitude = static_cast<float>(qRadiansToDegrees(qAsin(qBound(-1.0, sinAlt, 1.0))));

    // 太阳方位角
    double cosAz = (qSin(declRad) - qSin(latRad) * sinAlt)
                 / (qCos(latRad) * qCos(qAsin(qBound(-1.0, sinAlt, 1.0))));
    m_solarAzimuth = static_cast<float>(qRadiansToDegrees(qAcos(qBound(-1.0, cosAz, 1.0))));
    if (hourAngle > 0)
        m_solarAzimuth = 360.0f - m_solarAzimuth; // 下午方位角
}

float AstronomyModel::sunProgress() const
{
    int dayLength = m_sunsetMin - m_sunriseMin;
    if (dayLength <= 0) return 0.5f;
    float progress = static_cast<float>(m_currentMin - m_sunriseMin) / dayLength;
    return qBound(0.0f, progress, 1.0f);
}

float AstronomyModel::dayProgress() const
{
    int dayLength = m_sunsetMin - m_sunriseMin;
    if (dayLength <= 0) return 0.5f;
    return static_cast<float>(m_currentMin - m_sunriseMin) / dayLength;
}

bool AstronomyModel::isNight() const
{
    return (m_currentMin < m_sunriseMin || m_currentMin > m_sunsetMin);
}
