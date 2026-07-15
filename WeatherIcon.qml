import QtQuick
import QtQuick.Effects

// 和风天气图标组件 —— 根据 icon code 显示对应 SVG
// 用法：WeatherIcon { code: "100"; iconSize: 48 }
// 图标映射基于 https://dev.qweather.com/docs/resource/icons/
// 一一映射：code → SVG，不再依赖 isDay 做昼夜转换
Image {
    id: root
    property string code: "100"
    property int iconSize: 48
    property bool isDay: true  // 保留兼容性，不影响图标选择

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

    // 一一映射：天气码 → SVG 文件名
    source: {
        let c = parseInt(root.code)
        if (isNaN(c)) return ""
        const base = "https://icons.qweather.com/assets/icons/"

        if (c >= 800 && c <= 807) return base + c + ".svg"           // 月相
        if (c >= 150 && c <= 154) return base + c + ".svg"           // 夜间晴
        if (c >= 500 && c < 600)  return base + "500.svg"            // 雾/霾/沙尘

        if (c >= 400 && c < 500) {                                    // 雪
            if (c === 400 || c === 401) return base + "400.svg"
            if (c === 402 || c === 403) return base + "402.svg"
            if (c === 404 || c === 405) return base + "404.svg"
            if (c === 456 || c === 457) return base + "456.svg"
            return base + "406.svg"
        }
        if (c >= 300 && c < 400) {                                    // 雨
            if (c === 300 || c === 301) return base + "300.svg"
            if (c === 302 || c === 303) return base + "302.svg"
            if (c === 304) return base + "304.svg"
            if (c === 350 || c === 351) return base + "350.svg"
            return base + "305.svg"
        }
        if (c === 100) return base + "100.svg"
        if (c === 101 || c === 102) return base + "101.svg"
        if (c === 103) return base + "103.svg"
        if (c === 104) return base + "104.svg"
        return base + (c >= 100 && c <= 999 ? c + ".svg" : "100.svg")
    }
}
