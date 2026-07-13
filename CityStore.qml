import QtQuick

// 城市数据单例 —— 集中管理城市列表，所有页面共享
// 用法：CityStore { id: store }
//       store.addCity({name:"北京", id:"101010100"})
//       各页面绑定 store.trackedCities 即可
QtObject {
    id: store

    // 所有已追踪城市（最多 6 个）
    property var trackedCities: []

    // 焦点城市 ID
    property string focusCityId: ""

    // 城市分区固定城市（空 = 跟随焦点）
    property string pinnedCityId: ""

    // 城市天气缓存 { cityId: { temp, icon, text, ... } }
    property var cityWeather: ({})

    // 添加城市（自动去重，自动查天气）
    function addCity(cityObj) {
        for (var i = 0; i < trackedCities.length; i++) {
            if (trackedCities[i].id === cityObj.id) return
        }
        if (trackedCities.length >= 6) return  // 最多 6 个
        trackedCities.push(cityObj)
        trackedCitiesChanged()  // 通知绑定者刷新
    }

    function removeCity(id) {
        trackedCities = trackedCities.filter(function(c) { return c.id !== id })
        trackedCitiesChanged()
        if (focusCityId === id) {
            focusCityId = trackedCities.length > 0 ? trackedCities[0].id : ""
        }
    }

    function pinCity(id) {
        pinnedCityId = (pinnedCityId === id) ? "" : id
        pinnedCityIdChanged()
    }

    function updateWeather(id, temp, icon, text) {
        cityWeather[id] = { temp: temp, icon: icon, text: text }
        cityWeatherChanged()
    }

    function updateDaily(id, daily) {
        cityWeather[id] = cityWeather[id] || {}
        cityWeather[id].daily = daily
        cityWeatherChanged()
    }

    function updateHourly(id, hourly) {
        cityWeather[id] = cityWeather[id] || {}
        cityWeather[id].hourly = hourly
        cityWeatherChanged()
    }

    // 获取城市名
    function cityName(id) {
        for (var i = 0; i < trackedCities.length; i++) {
            if (trackedCities[i].id === id) return trackedCities[i].name
        }
        return id
    }
}
