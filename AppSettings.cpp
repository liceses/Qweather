#include "AppSettings.h"
#include <QSettings>

// AppSettings constructor: load persisted values / 构造函数：加载持久化设置
AppSettings::AppSettings(QObject* parent) : QObject(parent) {
    QSettings s;
    m_showSolarRadiation = s.value("showSolarRadiation", true).toBool();
    m_darkMode = s.value("darkMode", true).toBool();
    m_maxCards = s.value("maxCards", 4).toInt();
}

// Set solar radiation display toggle / 设置太阳辐射显示开关
void AppSettings::setShowSolarRadiation(bool show) {
    if (m_showSolarRadiation == show) return;
    m_showSolarRadiation = show;
    QSettings s;
    s.setValue("showSolarRadiation", show);
    emit showSolarRadiationChanged();
}

// Set dark mode toggle / 设置深色模式开关
void AppSettings::setDarkMode(bool dark) {
    if (m_darkMode == dark) return;
    m_darkMode = dark;
    QSettings s;
    s.setValue("darkMode", dark);
    emit darkModeChanged();
}

// Set maximum card count / 设置最大卡片数
void AppSettings::setMaxCards(int n) {
    if (m_maxCards == n) return;
    m_maxCards = n;
    QSettings s;
    s.setValue("maxCards", n);
    emit maxCardsChanged();
}
