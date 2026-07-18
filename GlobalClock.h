#pragma once
#include <QObject>
#include <QTimer>
#include <QElapsedTimer>

// GlobalClock — Global time source for ShaderEffect uniforms
// 全局时间源，16ms 时钟节拍，应用非活跃时自动暂停累加
// QML ShaderEffect 的 time uniform 可绑定到 globalClock.elapsed
class GlobalClock : public QObject {
    Q_OBJECT
    Q_PROPERTY(double elapsed READ elapsed NOTIFY tick)
public:
    // Constructor / 构造函数
    explicit GlobalClock(QObject *parent = nullptr);

    // elapsed — Current accumulated elapsed time in seconds / 当前累计运行时间（秒）
    double elapsed() const { return m_elapsed; }

    // start / stop / reset — Lifecycle control / 生命周期控制
    void start();
    void stop();
    void reset();

signals:
    // tick — Emitted every timer interval (≈16ms) / 每个时钟周期（约 16ms）触发
    void tick();

private slots:
    // onTick — Internal timer callback, accumulates elapsed time / 内部定时回调，累加运行时间
    void onTick();

private:
    QTimer m_timer;                  // 16ms periodic timer / 16ms 周期定时器
    QElapsedTimer m_elapsedTimer;    // High-resolution tick source / 高精度计时源
    double m_elapsed = 0.0;          // Total elapsed time in seconds / 累计运行时间（秒）
    double m_pauseOffset = 0.0;      // Time offset accumulated during pauses / 暂停期间偏移量
    bool m_running = false;          // Whether the clock is running / 时钟是否正在运行
};
