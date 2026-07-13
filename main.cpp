#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QJsonArray>
#include <QJsonObject>
#include "weatherApi.h"
#include "WeatherCache.h"
#include "ForecastStore.h"
#include "AirQualityStore.h"
#include "SolarAstronomyStore.h"
#include "CityDetailStore.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Fusion");
    QApplication app(argc, argv);

    qRegisterMetaType<QJsonArray>("QJsonArray");
    qRegisterMetaType<QJsonObject>("QJsonObject");

    WeatherCache cache;
    WeatherAPI weatherapi;
    weatherapi.setCache(&cache);

    ForecastStore forecastStore;
    forecastStore.setWeatherApi(&weatherapi);

    AirQualityStore airQualityStore;
    airQualityStore.setWeatherApi(&weatherapi);

    SolarAstronomyStore solarAstronomyStore;
    solarAstronomyStore.setWeatherApi(&weatherapi);

    CityDetailStore cityDetailStore;
    cityDetailStore.setWeatherApi(&weatherapi);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.rootContext()->setContextProperty("weatherApi", &weatherapi);
    engine.rootContext()->setContextProperty("forecastStore", &forecastStore);
    engine.rootContext()->setContextProperty("airQualityStore", &airQualityStore);
    engine.rootContext()->setContextProperty("solarAstronomyStore", &solarAstronomyStore);
    engine.rootContext()->setContextProperty("cityDetailStore", &cityDetailStore);
    engine.loadFromModule("qml1", "Main");

    return QApplication::exec();
}
