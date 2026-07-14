#include "AppSettings.h"
#include <QSettings>

AppSettings::AppSettings(QObject* parent) : QObject(parent) {
    QSettings s;
    m_showSolarRadiation = s.value("showSolarRadiation", true).toBool();
    m_darkMode = s.value("darkMode", true).toBool();
}

void AppSettings::setShowSolarRadiation(bool show) {
    if (m_showSolarRadiation == show) return;
    m_showSolarRadiation = show;
    QSettings s;
    s.setValue("showSolarRadiation", show);
    emit showSolarRadiationChanged();
}

void AppSettings::setDarkMode(bool dark) {
    if (m_darkMode == dark) return;
    m_darkMode = dark;
    QSettings s;
    s.setValue("darkMode", dark);
    emit darkModeChanged();
}
