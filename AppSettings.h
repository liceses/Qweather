#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QString>

// AppSettings — Application-wide settings & theme color tokens
// 全局应用设置与主题色令牌，darkMode 切换自动更新 QML 绑定
class AppSettings : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool showSolarRadiation READ showSolarRadiation WRITE setShowSolarRadiation NOTIFY showSolarRadiationChanged)
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)
    Q_PROPERTY(int maxCards READ maxCards WRITE setMaxCards NOTIFY maxCardsChanged)

    // 主题颜色令牌（由 darkMode 决定，只读）
    Q_PROPERTY(QString iconColor      READ iconColor      NOTIFY darkModeChanged)
    Q_PROPERTY(QString iconInactive   READ iconInactive   NOTIFY darkModeChanged)
    Q_PROPERTY(QString textPrimary    READ textPrimary    NOTIFY darkModeChanged)
    Q_PROPERTY(QString textSecondary  READ textSecondary  NOTIFY darkModeChanged)
    Q_PROPERTY(QString textTertiary   READ textTertiary   NOTIFY darkModeChanged)
    Q_PROPERTY(QString cardBg         READ cardBg         NOTIFY darkModeChanged)
    Q_PROPERTY(QString cardBorder     READ cardBorder     NOTIFY darkModeChanged)
    Q_PROPERTY(QString sidebarBg      READ sidebarBg      NOTIFY darkModeChanged)
    Q_PROPERTY(QString accentColor    READ accentColor    NOTIFY darkModeChanged)
    Q_PROPERTY(QString bgStart        READ bgStart        NOTIFY darkModeChanged)
    Q_PROPERTY(QString bgEnd          READ bgEnd          NOTIFY darkModeChanged)

public:
    explicit AppSettings(QObject* parent = nullptr);

    // Show/hide solar radiation card / 显示/隐藏太阳辐射卡片
    bool showSolarRadiation() const { return m_showSolarRadiation; }
    void setShowSolarRadiation(bool show);

    // Dark/light mode toggle / 深色/浅色模式切换
    bool darkMode() const { return m_darkMode; }
    void setDarkMode(bool dark);

    // Maximum number of forecast cards / 预报卡片最大数量
    int maxCards() const { return m_maxCards; }
    void setMaxCards(int n);

    // Theme color tokens (auto-switch on darkMode) / 主题色令牌（跟随 darkMode 自动切换）
    QString iconColor() const      { return m_darkMode ? "#ffffff" : "#1a1a1a"; }
    QString iconInactive() const   { return m_darkMode ? "#ccffffff" : "#808080"; }
    QString textPrimary() const    { return m_darkMode ? "#ffffff" : "#1a1a1a"; }
    QString textSecondary() const  { return m_darkMode ? "#ccffffff" : "#4a4a4a"; }
    QString textTertiary() const   { return m_darkMode ? "#80ffffff" : "#808080"; }
    QString cardBg() const         { return m_darkMode ? "#20ffffff" : "#20000000"; }
    QString cardBorder() const     { return m_darkMode ? "#30ffffff" : "#30000000"; }
    QString sidebarBg() const      { return m_darkMode ? "#1a000000" : "#1affffff"; }
    QString accentColor() const    { return "#4caf50"; }               // Fixed accent green / 固定强调色
    QString bgStart() const        { return m_darkMode ? "#2e7d32" : "#e8f5e9"; }  // Background gradient start / 背景渐变起点
    QString bgEnd() const          { return m_darkMode ? "#81c784" : "#c8e6c9"; }  // Background gradient end / 背景渐变终点

signals:
    void showSolarRadiationChanged();
    void darkModeChanged();
    void maxCardsChanged();

private:
    bool m_showSolarRadiation = true;  // Solar radiation card visibility / 太阳辐射卡片可见性
    bool m_darkMode = true;            // Dark mode enabled / 深色模式启用
    int m_maxCards = 4;                // Max forecast cards / 最大预报卡片数
};

#endif
