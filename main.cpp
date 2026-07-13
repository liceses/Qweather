#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QJsonArray>
#include <QJsonObject>
#include "weatherApi.h"
#include "WeatherCache.h"

int main(int argc, char *argv[])
{
    // Fusion 风格：通过环境变量在 QGuiApplication 构造前设置
    qputenv("QT_QUICK_CONTROLS_STYLE", "Fusion");
    QGuiApplication app(argc, argv);

    qRegisterMetaType<QJsonArray>("QJsonArray");
    qRegisterMetaType<QJsonObject>("QJsonObject");

    WeatherCache cache;
    WeatherAPI weatherapi;
    weatherapi.setCache(&cache);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.rootContext()->setContextProperty("weatherApi", &weatherapi);
    engine.loadFromModule("qml1", "Main");

    return QGuiApplication::exec();
}
