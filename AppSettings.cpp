#include "AppSettings.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QCoreApplication>

// AppSettings constructor: load persisted values / 构造函数：加载持久化设置
AppSettings::AppSettings(QObject* parent) : QObject(parent) {
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    m_configPath = dataDir + "/settings.json";
    loadFromFile();
}

// Load settings from JSON file / 从 JSON 文件加载设置
void AppSettings::loadFromFile() {
    QFile f(m_configPath);
    if (!f.open(QIODevice::ReadOnly)) return;
    QJsonObject root = QJsonDocument::fromJson(f.readAll()).object();
    m_showSolarRadiation = root.value("showSolarRadiation").toBool(true);
    m_darkMode = root.value("darkMode").toBool(true);
    m_maxCards = root.value("maxCards").toInt(4);
}

// Save settings to JSON file / 保存设置到 JSON 文件
void AppSettings::saveToFile() {
    QJsonObject root;
    root["showSolarRadiation"] = m_showSolarRadiation;
    root["darkMode"] = m_darkMode;
    root["maxCards"] = m_maxCards;
    QFile f(m_configPath);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
}

// Set solar radiation display toggle / 设置太阳辐射显示开关
void AppSettings::setShowSolarRadiation(bool show) {
    if (m_showSolarRadiation == show) return;
    m_showSolarRadiation = show;
    saveToFile();
    emit showSolarRadiationChanged();
}

// Set dark mode toggle / 设置深色模式开关
void AppSettings::setDarkMode(bool dark) {
    if (m_darkMode == dark) return;
    m_darkMode = dark;
    saveToFile();
    emit darkModeChanged();
}

// Set maximum card count / 设置最大卡片数
void AppSettings::setMaxCards(int n) {
    if (m_maxCards == n) return;
    m_maxCards = n;
    saveToFile();
    emit maxCardsChanged();
}
