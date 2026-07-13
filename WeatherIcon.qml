import QtQuick

Image {
    id: root
    property string code: "100"       // 和风天气 icon code
    property int iconSize: 48
    property bool isDay: true

    width: iconSize
    height: iconSize
    sourceSize.width: iconSize
    sourceSize.height: iconSize
    fillMode: Image.PreserveAspectFit

    source: {
        let c = parseInt(code)
        if (isNaN(c)) return ""
        // 和风天气图标项目: https://icons.qweather.com/
        // 100 晴  104 阴  300-318 雨  400-410 雪
        if (!isDay) {
            // 夜间
            if (c === 100) return "https://icons.qweather.com/assets/icons/150.svg"
            if (c === 101 || c === 102) return "https://icons.qweather.com/assets/icons/151.svg"
            if (c === 103) return "https://icons.qweather.com/assets/icons/152.svg"
            if (c === 104) return "https://icons.qweather.com/assets/icons/154.svg"
            if (c >= 300 && c < 400) return "https://icons.qweather.com/assets/icons/350.svg"
            if (c >= 400 && c < 500) return "https://icons.qweather.com/assets/icons/450.svg"
            return "https://icons.qweather.com/assets/icons/150.svg"
        }
        // 白天
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
