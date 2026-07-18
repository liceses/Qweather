#include "GlobalClock.h"
#include <QDebug>

// GlobalClock constructor / 全局时钟构造函数
GlobalClock::GlobalClock(QObject *parent)
    : QObject(parent)
{
    m_timer.setTimerType(Qt::PreciseTimer);     // Precise timer for smooth animation / 精确计时器保证动画平滑
    m_timer.setInterval(16);                     // ~60fps (16ms per tick)
    connect(&m_timer, &QTimer::timeout, this, &GlobalClock::onTick);
}

// Start the global clock / 启动全局时钟
void GlobalClock::start()
{
    if (m_running) return;                       // Already running / 已在运行
    m_elapsedTimer.start();                      // Start elapsed time counter / 开始计时
    m_timer.start();                             // Start tick timer / 启动滴答定时器
    m_running = true;
    qDebug() << "[GlobalClock] started, interval=16ms";
}

// Stop the global clock / 停止全局时钟
void GlobalClock::stop()
{
    if (!m_running) return;
    m_timer.stop();
    m_pauseOffset = m_elapsed;                   // Save elapsed time / 保存已过时间
    m_running = false;
    qDebug() << "[GlobalClock] stopped at elapsed=" << m_elapsed;
}

// Reset elapsed time / 重置已过时间
void GlobalClock::reset()
{
    m_elapsed = 0.0;
    m_pauseOffset = 0.0;
    if (m_running) {
        m_elapsedTimer.restart();                // Restart from zero / 从头计时
    }
    qDebug() << "[GlobalClock] reset";
}

// Tick callback – accumulates elapsed seconds / 滴答回调——累计经过秒数
void GlobalClock::onTick()
{
    double secs = m_pauseOffset + m_elapsedTimer.elapsed() / 1000.0;
    if (qFuzzyCompare(m_elapsed, secs))
        return;                                  // No change / 无变化
    m_elapsed = secs;
    emit tick();
}
