import QtQuick
import QtQuick.Effects

// 和风天气图标组件 —— 根据 icon code 显示对应 SVG
// 用法：WeatherIcon { code: "100"; iconSize: 48; isDay: true }
// Qt6 标准 SVG 染色：layer.effect MultiEffect (brightness + colorization)
Image {
    id: root
    property string code: "100"
    property int iconSize: 48
    property bool isDay: true

    width: iconSize
    height: iconSize
    sourceSize.width: iconSize
    sourceSize.height: iconSize
    fillMode: Image.PreserveAspectFit

    readonly property bool _dark: appSettings ? appSettings.darkMode : true

    layer.enabled: true
    layer.effect: MultiEffect {
        brightness: 1.0
        colorization: 1.0
        colorizationColor: root._dark ? "#1a1a1a" : "#ccffffff"
    }

    source: {
        let c = parseInt(root.code)
        if (isNaN(c)) return ""
        if (!root.isDay) {
            if (c === 100) return "https://icons.qweather.com/assets/icons/150.svg"
            if (c === 101 || c === 102) return "https://icons.qweather.com/assets/icons/151.svg"
            if (c === 103) return "https://icons.qweather.com/assets/icons/152.svg"
            if (c === 104) return "https://icons.qweather.com/assets/icons/154.svg"
            if (c >= 300 && c < 400) return "https://icons.qweather.com/assets/icons/350.svg"
            if (c >= 400 && c < 500) return "https://icons.qweather.com/assets/icons/450.svg"
            return "https://icons.qweather.com/assets/icons/150.svg"
        }
        if (c === 100) return "https://icons.qweather.com/assets/icons/100.svg"
        if (c === 101 || c === 102) return "https://icons.qweather.com/assets/icons/101.svg"
        if (c === 103) return "https://icons.qweather.com/assets/icons/102.svg"
        if (c === 104) return "https://icons.qweather.com/assets/icons/104.svg"
        if (c >= 300 && c < 400) {
            if (c === 300 || c === 301) return "https://icons.qweather.com/assets/icons/300.svg"
            if (c === 302 || c === 303) return "https://icons.qweather.com/assets/icons/302.svg"
            if (c === 304 || c === 305) return "https://icons.qweather.com/assets/icons/304.svg"
            return "https://icons.qweather.com/assets/icons/305.svg"
        }
        if (c >= 400 && c < 500) {
            if (c === 400 || c === 401) return "https://icons.qweather.com/assets/icons/400.svg"
            if (c === 402 || c === 403) return "https://icons.qweather.com/assets/icons/402.svg"
            if (c === 404 || c === 405) return "https://icons.qweather.com/assets/icons/404.svg"
            return "https://icons.qweather.com/assets/icons/406.svg"
        }
        if (c >= 500 && c < 600) return "https://icons.qweather.com/assets/icons/500.svg"
        return "https://icons.qweather.com/assets/icons/100.svg"
    }
}
