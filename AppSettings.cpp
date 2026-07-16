#include "AppSettings.h"
#include <QSettings>

AppSettings::AppSettings(QObject* parent) : QObject(parent) {
    QSettings s;
    m_showSolarRadiation = s.value("showSolarRadiation", true).toBool();
    m_darkMode = s.value("darkMode", true).toBool();
    m_maxCards = s.value("maxCards", 4).toInt();
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

void AppSettings::setMaxCards(int n) {
    if (m_maxCards == n) return;
    m_maxCards = n;
    QSettings s;
    s.setValue("maxCards", n);
    emit maxCardsChanged();
}
