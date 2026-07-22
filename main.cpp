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
#include "AppSettings.h"
#include "GlobalClock.h"
#include "BackgroundManager.h"
#include "TransitionController.h"
#include "SkyState.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Fusion");
    QApplication app(argc, argv);
    app.setApplicationName("QWeather");
    app.setOrganizationName("QWeatherApp");

    qRegisterMetaType<QJsonArray>("QJsonArray");
    qRegisterMetaType<QJsonObject>("QJsonObject");

    WeatherCache cache;
    WeatherAPI weatherapi;
    weatherapi.setCache(&cache);
    weatherapi.loadCounts();

    ForecastStore forecastStore;
    forecastStore.setWeatherApi(&weatherapi);

    AirQualityStore airQualityStore;
    airQualityStore.setWeatherApi(&weatherapi);

    AppSettings appSettings;

    // Migrate: fill default API key on first launch / 首次启动自动填充旧 key
    if (appSettings.apiKey().isEmpty())
        appSettings.setApiKey("ac6fe42e65be4a79a9eca8fc5043c2bf");
    weatherapi.setApiConfig(appSettings.apiKey(), appSettings.apiHost());

    // Runtime sync: when user changes API config in settings / 运行时同步用户在设置页改配置
    QObject::connect(&appSettings, &AppSettings::apiKeyChanged, &weatherapi, [&]() {
        weatherapi.setApiConfig(appSettings.apiKey(), appSettings.apiHost());
    });
    QObject::connect(&appSettings, &AppSettings::apiHostChanged, &weatherapi, [&]() {
        weatherapi.setApiConfig(appSettings.apiKey(), appSettings.apiHost());
    });

    SolarAstronomyStore solarAstronomyStore;
    solarAstronomyStore.setWeatherApi(&weatherapi);
    solarAstronomyStore.setAppSettings(&appSettings);

    CityDetailStore cityDetailStore;
    cityDetailStore.setWeatherApi(&weatherapi);

    // === V3 天空系统 ===
    qRegisterMetaType<SkyState>("SkyState");
    GlobalClock globalClock;
    BackgroundManager bgManager;
    TransitionController transitionCtrl;
    bgManager.setTransitionController(&transitionCtrl);

    globalClock.start();

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.rootContext()->setContextProperty("weatherApi", &weatherapi);
    engine.rootContext()->setContextProperty("weatherCache", &cache);
    engine.rootContext()->setContextProperty("forecastStore", &forecastStore);
    engine.rootContext()->setContextProperty("airQualityStore", &airQualityStore);
    engine.rootContext()->setContextProperty("solarAstronomyStore", &solarAstronomyStore);
    engine.rootContext()->setContextProperty("cityDetailStore", &cityDetailStore);
    engine.rootContext()->setContextProperty("appSettings", &appSettings);
    engine.rootContext()->setContextProperty("globalClock", &globalClock);
    engine.rootContext()->setContextProperty("backgroundManager", &bgManager);
    engine.rootContext()->setContextProperty("transitionCtrl", &transitionCtrl);
    engine.loadFromModule("qml1", "Main");

    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&]() {
        weatherapi.saveCounts();
    });

    return QApplication::exec();
}
