#pragma once
#include <QObject>
#include <QTimer>
#include <QElapsedTimer>

// GlobalClock: 全局时间源
// 16ms tick，应用非活跃时暂停累加
// QML ShaderEffect 的 time uniform 绑定 globalClock.elapsed
class GlobalClock : public QObject {
    Q_OBJECT
    Q_PROPERTY(double elapsed READ elapsed NOTIFY tick)
public:
    explicit GlobalClock(QObject *parent = nullptr);

    double elapsed() const { return m_elapsed; }

    void start();
    void stop();
    void reset();

signals:
    void tick();

private slots:
    void onTick();

private:
    QTimer m_timer;
    QElapsedTimer m_elapsedTimer;
    double m_elapsed = 0.0;
    double m_pauseOffset = 0.0;
    bool m_running = false;
};
