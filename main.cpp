#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QJsonArray>
#include <QJsonObject>
#include "weatherApi.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 注册 QJson 类型，确保 QML Connections 能匹配信号参数
    qRegisterMetaType<QJsonArray>("QJsonArray");
    qRegisterMetaType<QJsonObject>("QJsonObject");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    WeatherAPI weatherapi;
    engine.rootContext()->setContextProperty("weatherApi", &weatherapi);
    engine.loadFromModule("qml1", "Main");

    return QGuiApplication::exec();
}
