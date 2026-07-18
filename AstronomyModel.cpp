#include "AstronomyModel.h"
#include <QDebug>
#include <QtMath>
#include <QTime>

// AstronomyModel constructor / 天文模型构造函数
AstronomyModel::AstronomyModel(QObject *parent)
    : QObject(parent)
{
    qDebug() << "[AstronomyModel] created, default location: lat=" << m_lat << "lon=" << m_lon;
}

// Set geographic lat/lon and compute time offset in minutes / 设置地理经纬度并计算分钟时差
void AstronomyModel::setLocation(float lat, float lon)
{
    m_lat = lat;
    m_lon = lon;
    m_lonOffset = qBound(-720, static_cast<int>(lon / 15.0f * 60.0f), 720); // 1h per 15° / 每15度1小时
    qDebug() << "[AstronomyModel] setLocation: lat=" << lat << "lon=" << lon
             << "offset=" << m_lonOffset << "min";
}

// Set sunrise/sunset times; accepts ISO or "HH:mm" format / 设置日出/日落时间，支持 ISO 或 "HH:mm" 格式
void AstronomyModel::setSunTimes(const QString &sunrise, const QString &sunset)
{
    auto toMinutes = [](const QString &t) -> int {
        QDateTime dt = QDateTime::fromString(t, Qt::ISODate);
        if (dt.isValid())
            return dt.time().hour() * 60 + dt.time().minute();
        auto parts = t.split(':');
        if (parts.size() >= 2)
            return parts[0].toInt() * 60 + parts[1].toInt();
        return 360;                                  // default 06:00 / 默认06:00
    };

    m_sunriseMin = toMinutes(sunrise);
    m_sunsetMin  = toMinutes(sunset);
    qDebug() << "[AstronomyModel] sunTimes: sunrise=" << sunrise
             << "(" << m_sunriseMin << "min)"
             << "sunset=" << sunset
             << "(" << m_sunsetMin << "min)";
}

// Set moon phase icon and illumination / 设置月相图标和照明度
void AstronomyModel::setMoonData(int phaseIcon, float illumination)
{
    m_moonPhase = static_cast<float>(phaseIcon);
    m_moonIllum = illumination;
    qDebug() << "[AstronomyModel] moonData: phaseIcon=" << phaseIcon
             << "illumination=" << illumination;
}

// Update all astronomical values from epoch milliseconds / 从纪元毫秒更新所有天文值
void AstronomyModel::update(qint64 nowMsecs)
{
    QDateTime dt = QDateTime::fromMSecsSinceEpoch(nowMsecs, Qt::UTC);  // UTC time / UTC时间
    m_dayOfYear = dt.date().dayOfYear();
    int utcMin = dt.time().hour() * 60 + dt.time().minute();
    int minuteOfDay = utcMin + m_lonOffset;                             // Adjust for longitude / 按经度调整
    minuteOfDay = ((minuteOfDay % 1440) + 1440) % 1440;                 // Wrap to [0,1440) / 归到一日内
    m_currentMin = minuteOfDay;

    qDebug() << "[AstronomyModel] update:"
             << "UTC epoch msecs=" << nowMsecs
             << "dt(time)=" << dt.time()
             << "dt(spec)=" << dt.timeSpec()
             << "utcMin=" << utcMin
             << "lonOffset=" << m_lonOffset
             << "→ minuteOfDay=" << minuteOfDay;

    calcSolarPosition(m_dayOfYear, minuteOfDay);

    // Simplified moon position: mirror sun across the Earth / 简化月亮位置：取太阳对跖点偏移
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

// Update from a raw minute-of-day value (debug mode) / 从分钟数更新（调试模式）
void AstronomyModel::updateByMinute(int minuteOfDay)
{
    minuteOfDay = qBound(0, minuteOfDay, 1440);
    m_currentMin = minuteOfDay;

    calcSolarPosition(m_dayOfYear, minuteOfDay);

    // Simplified moon position / 简化月亮位置
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

// Calculate solar altitude & azimuth using simplified astronomical formulas / 使用简化天文公式计算太阳高度角和方位角
void AstronomyModel::calcSolarPosition(int dayOfYear, int minuteOfDay)
{
    // Solar declination: 23.45° * sin(2π*(dayOfYear-81)/365) / 太阳赤纬
    double declination = 23.45 * qSin(2.0 * M_PI * (dayOfYear - 81) / 365.0);

    // Hour angle: (current time - noon) * 15°/h / 时角
    double hourAngle = (minuteOfDay - 720) * 0.25;  // degrees / 度

    double latRad = qDegreesToRadians(static_cast<double>(m_lat));
    double declRad = qDegreesToRadians(declination);
    double haRad = qDegreesToRadians(hourAngle);

    // Solar altitude angle / 太阳高度角
    double sinAlt = qSin(latRad) * qSin(declRad)
                  + qCos(latRad) * qCos(declRad) * qCos(haRad);
    m_solarAltitude = static_cast<float>(qRadiansToDegrees(qAsin(qBound(-1.0, sinAlt, 1.0))));

    // Solar azimuth angle / 太阳方位角
    double cosAz = (qSin(declRad) - qSin(latRad) * sinAlt)
                 / (qCos(latRad) * qCos(qAsin(qBound(-1.0, sinAlt, 1.0))));
    m_solarAzimuth = static_cast<float>(qRadiansToDegrees(qAcos(qBound(-1.0, cosAz, 1.0))));
    if (hourAngle > 0)
        m_solarAzimuth = 360.0f - m_solarAzimuth;  // Afternoon / 下午方位角翻转
}

// Sun progress within the day [0,1] / 白昼中的太阳进度 [0,1]
float AstronomyModel::sunProgress() const
{
    int dayLength = m_sunsetMin - m_sunriseMin;
    if (dayLength <= 0) return 0.5f;
    float progress = static_cast<float>(m_currentMin - m_sunriseMin) / dayLength;
    return qBound(0.0f, progress, 1.0f);
}

// Day progress (same as sunProgress) / 白昼进度（同 sunProgress）
float AstronomyModel::dayProgress() const
{
    int dayLength = m_sunsetMin - m_sunriseMin;
    if (dayLength <= 0) return 0.5f;
    return static_cast<float>(m_currentMin - m_sunriseMin) / dayLength;
}

// Check if current time is night / 判断是否为夜晚
bool AstronomyModel::isNight() const
{
    return (m_currentMin < m_sunriseMin || m_currentMin > m_sunsetMin);
}
