#include "GlobalClock.h"
#include <QDebug>

GlobalClock::GlobalClock(QObject *parent)
    : QObject(parent)
{
    m_timer.setTimerType(Qt::PreciseTimer);
    m_timer.setInterval(16); // ~60fps
    connect(&m_timer, &QTimer::timeout, this, &GlobalClock::onTick);
}

void GlobalClock::start()
{
    if (m_running) return;
    m_elapsedTimer.start();
    m_timer.start();
    m_running = true;
    qDebug() << "[GlobalClock] started, interval=16ms";
}

void GlobalClock::stop()
{
    if (!m_running) return;
    m_timer.stop();
    m_pauseOffset = m_elapsed;
    m_running = false;
    qDebug() << "[GlobalClock] stopped at elapsed=" << m_elapsed;
}

void GlobalClock::reset()
{
    m_elapsed = 0.0;
    m_pauseOffset = 0.0;
    if (m_running) {
        m_elapsedTimer.restart();
    }
    qDebug() << "[GlobalClock] reset";
}

void GlobalClock::onTick()
{
    // 累计经过的秒数
    double secs = m_pauseOffset + m_elapsedTimer.elapsed() / 1000.0;
    if (qFuzzyCompare(m_elapsed, secs))
        return; // 无变化
    m_elapsed = secs;
    emit tick();
}
