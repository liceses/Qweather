cmake_minimum_required(VERSION 3.16)

project(qml1 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network Sql Charts Widgets)

qt_standard_project_setup(REQUIRES 6.10)

if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(appqml1
    main.cpp
)

qt_add_qml_module(appqml1
    URI qml1
    QML_FILES
        Main.qml
        NavButton.qml
        SearchBar.qml
        WeatherIcon.qml
        CityCard.qml
        ForecastPage.qml
        ForecastCard.qml
        AirQualityPage.qml
        AirQualityCard.qml
        SolarAstronomyPage.qml
        SolarAstronomyCard.qml
        CityDetailPage.qml
    SOURCES weatherApi.h weatherApi.cpp
    SOURCES WeatherCache.h WeatherCache.cpp
    SOURCES ForecastStore.h ForecastStore.cpp
    SOURCES AirQualityStore.h AirQualityStore.cpp
    SOURCES SolarAstronomyStore.h SolarAstronomyStore.cpp
    SOURCES CityDetailStore.h CityDetailStore.cpp
)

set_target_properties(appqml1 PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appqml1
    PRIVATE Qt6::Quick Qt6::Network Qt6::Sql Qt6::Charts Qt6::Widgets
)

install(TARGETS appqml1
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
