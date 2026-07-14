import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 城市详情页 —— 滚动卡片堆叠展示该城市所有可获取信息
// 绑定 cityDetailStore.detail，各卡片按数据到达依次出现
Flickable {
    id: page
    clip: true
    contentHeight: column.implicitHeight + 32
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    property var detail: cityDetailStore.detail || ({})
    property bool favorited: false
    property var onToggleFav: function() {}

    Column {
        id: column
        width: parent.width
        padding: 16
        spacing: 12

        // ========== 城市名大标题 + 收藏星标 ==========
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Text {
                id: cityTitle
                text: detail.cityName || "选择城市"
                color: "white"
                font.pixelSize: 40
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            // 收藏星标
            Rectangle {
                id: starBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36; radius: 18
                color: starMouse.containsMouse ? "#35000000" : "transparent"
                visible: !!detail.cityName

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: page.favorited ? "★" : "☆"
                    color: page.favorited ? "#ffc107" : "#80ffffff"
                    font.pixelSize: 22
                }

                MouseArea {
                    id: starMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.onToggleFav()
                }
            }
        }

        // 无城市提示
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "请从仪表盘双击城市卡片，或在侧边栏选择城市"
            color: "#80ffffff"
            font.pixelSize: 14
            visible: !detail.cityName
        }

        // ===== 卡片1: 实时天气 =====
        Rectangle {
            id: nowCard
            width: parent.width - parent.padding * 2
            height: nowContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: nowHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: !!detail.now && !!detail.now.temp

            ColumnLayout {
                id: nowContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 10

                Text { text: "实时天气"; color: "white"; font.pixelSize: 16; font.bold: true }

                RowLayout {
                    spacing: 16
                    WeatherIcon { code: detail.now.icon || "100"; iconSize: 64; isDay: true }
                    ColumnLayout { spacing: 2
                        Text { text: (detail.now.temp || "--") + "°"; color: "white"; font.pixelSize: 42; font.bold: true }
                        Text { text: "体感 " + (detail.now.feelsLike || "--") + "°"; color: "#ccffffff"; font.pixelSize: 14 }
                        Text { text: detail.now.text || ""; color: "white"; font.pixelSize: 18 }
                    }
                }

                Grid {
                    id: nowGrid
                    columns: 3; spacing: 6
                    Layout.fillWidth: true
                    DetailChip { width: (nowCard.width - 24 - nowGrid.spacing * 2) / 3; label: "风向"; value: (detail.now.windDir||"") + " " + (detail.now.windScale||"") + "级" }
                    DetailChip { width: (nowCard.width - 24 - nowGrid.spacing * 2) / 3; label: "风速"; value: (detail.now.windSpeed || "--") + " km/h" }
                    DetailChip { width: (nowCard.width - 24 - nowGrid.spacing * 2) / 3; label: "湿度"; value: (detail.now.humidity || "--") + "%" }
                    DetailChip { width: (nowCard.width - 24 - nowGrid.spacing * 2) / 3; label: "气压"; value: (detail.now.pressure || "--") + " hPa" }
                    DetailChip { width: (nowCard.width - 24 - nowGrid.spacing * 2) / 3; label: "能见度"; value: (detail.now.vis || "--") + " km" }
                    DetailChip { width: (nowCard.width - 24 - nowGrid.spacing * 2) / 3; label: "降水量"; value: (detail.now.precip || "0") + " mm" }
                }
            }

            MouseArea {
                id: nowHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // ===== 卡片2: 空气质量 =====
        Rectangle {
            id: airCard
            width: parent.width - parent.padding * 2
            height: airContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: airHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: !!detail.air && !!detail.air.aqi

            ColumnLayout {
                id: airContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 8

                Text { text: "空气质量"; color: "white"; font.pixelSize: 16; font.bold: true }

                RowLayout { spacing: 12
                    Rectangle {
                        width: 16; height: 16; radius: 8
                        color: detail.air.color || "#888"
                    }
                    Text {
                        text: detail.air.aqi || "--"
                        color: "white"; font.pixelSize: 36; font.bold: true
                    }
                    Text {
                        text: detail.air.category || ""
                        color: detail.air.color || "white"; font.pixelSize: 18
                    }
                }

                Text {
                    text: detail.air.primaryPollutant ? "首要污染物: " + detail.air.primaryPollutant : ""
                    color: "#aaffffff"; font.pixelSize: 13
                    visible: text !== ""
                }
                Text {
                    text: detail.air.healthEffect || ""
                    color: "#ccffffff"; font.pixelSize: 12; wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    visible: text !== ""
                }

                Grid {
                    id: airGrid
                    columns: 3; spacing: 4
                    Layout.fillWidth: true
                    Repeater {
                        model: detail.air.pollutants || []
                        Rectangle {
                            width: (airCard.width - 24 - airGrid.spacing * 2) / 3
                            height: 28; radius: 4
                            color: "#15ffffff"
                            border.width: 1; border.color: "#20ffffff"
                            Row {
                                anchors.centerIn: parent; spacing: 4
                                Text { text: modelData.name || ""; color: "#ccffffff"; font.pixelSize: 10 }
                                Text { text: (modelData.value!==undefined?modelData.value:"--")+" "+ (modelData.unit||""); color: "white"; font.pixelSize: 10; font.bold: true }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: airHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // ===== 卡片3: 逐日预报 =====
        Rectangle {
            id: dailyCard
            width: parent.width - parent.padding * 2
            height: dailyContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: dailyHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: !!detail.daily && detail.daily.length > 0

            ColumnLayout {
                id: dailyContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 8

                Text { text: "3日预报"; color: "white"; font.pixelSize: 16; font.bold: true }

                Row {
                    spacing: 12
                    Layout.fillWidth: true
                    Repeater {
                        model: detail.daily || []
                        Rectangle {
                            width: (dailyContent.width - 24) / 3
                            height: 130; radius: 8
                            color: "#15ffffff"
                            border.width: 1; border.color: "#20ffffff"
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 4
                                Text {
                                    text: modelData.fxDate ? modelData.fxDate.slice(5) : ""
                                    color: "white"; font.pixelSize: 12
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                WeatherIcon { code: modelData.iconDay || "100"; iconSize: 28; Layout.alignment: Qt.AlignHCenter }
                                Text { text: modelData.textDay || ""; color: "#ccffffff"; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
                                Text { text: (modelData.tempMin||"--") + "°~" + (modelData.tempMax||"--") + "°"; color: "white"; font.pixelSize: 14; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                                Text { text: (modelData.windDirDay||"") + " " + (modelData.windScaleDay||""); color: "#80ffffff"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: dailyHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // ===== 卡片4: 逐小时预报 =====
        Rectangle {
            id: hourlyCard
            width: parent.width - parent.padding * 2
            height: hourlyContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: hourlyHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: !!detail.hourly && detail.hourly.length > 0

            ColumnLayout {
                id: hourlyContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 8

                Text { text: "24小时预报"; color: "white"; font.pixelSize: 16; font.bold: true }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    contentWidth: hourRow.width
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Row {
                        id: hourRow; spacing: 8
                        Repeater {
                            model: detail.hourly || []
                            Rectangle {
                                width: 60; height: 80; radius: 6
                                color: "#15ffffff"
                                border.width: 1; border.color: "#20ffffff"
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 2
                                    Text { text: modelData.fxTime ? modelData.fxTime.slice(11, 16) : ""; color: "#ccffffff"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                                    WeatherIcon { code: modelData.icon || "100"; iconSize: 22; Layout.alignment: Qt.AlignHCenter }
                                    Text { text: modelData.temp ? modelData.temp + "°" : ""; color: "white"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                                    Text { text: modelData.pop ? modelData.pop + "%" : ""; color: "#80ffffff"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter; visible: text !== "" }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: hourlyHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // ===== 卡片5: 天气指数 =====
        Rectangle {
            id: indicesCard
            width: parent.width - parent.padding * 2
            height: indicesContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: indicesHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: !!detail.indices && detail.indices.length > 0

            ColumnLayout {
                id: indicesContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 6

                Text { text: "生活指数"; color: "white"; font.pixelSize: 16; font.bold: true }

                Grid {
                    id: indicesGrid
                    columns: 4; spacing: 6
                    Layout.fillWidth: true
                    Repeater {
                        model: detail.indices || []
                        Rectangle {
                            width: (indicesCard.width - 24 - indicesGrid.spacing * 3) / 4
                            height: 56; radius: 6
                            color: "#15ffffff"
                            border.width: 1; border.color: "#20ffffff"
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 1
                                Text { text: modelData.name || ""; color: "white"; font.pixelSize: 11; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                                Text { text: modelData.category || ""; color: "#aaffffff"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                                Text { text: "等级 " + (modelData.level||""); color: "#80ffffff"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: indicesHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // ===== 卡片6: 天气预警 =====
        Rectangle {
            id: warningCard
            width: parent.width - parent.padding * 2
            height: warningContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: warningHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: !!detail.warnings && detail.warnings.length > 0

            ColumnLayout {
                id: warningContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 8

                Text { text: "天气预警"; color: "white"; font.pixelSize: 16; font.bold: true }

                Repeater {
                    model: detail.warnings || []
                    ColumnLayout {
                        spacing: 6
                        Layout.fillWidth: true

                        Rectangle {
                            Layout.fillWidth: true; height: 1; color: "#30ffffff"
                        }

                        RowLayout { spacing: 8
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: modelData.severityColor || "#ff9800"
                            }
                            Text { text: modelData.eventName || ""; color: modelData.severityColor || "#ff9800"; font.pixelSize: 14; font.bold: true }
                            Text { text: modelData.severity || ""; color: "#ccffffff"; font.pixelSize: 12 }
                        }
                        Text {
                            text: modelData.headline || ""; color: "white"; font.pixelSize: 13
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.description || ""; color: "#aaffffff"; font.pixelSize: 11
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                            maximumLineCount: 4; elide: Text.ElideRight
                        }
                    }
                }
            }

            MouseArea {
                id: warningHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // ===== 卡片7: 天文 —— 日出日落 + 月相 =====
        Rectangle {
            id: astroCard
            width: parent.width - parent.padding * 2
            height: astroContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: astroHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: (!!detail.sun && !!detail.sun.sunrise) || (!!detail.moon && !!detail.moon.moonPhase)

            ColumnLayout {
                id: astroContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 8

                Text { text: "天文"; color: "white"; font.pixelSize: 16; font.bold: true }

                RowLayout {
                    spacing: 24

                    ColumnLayout {
                        spacing: 4
                        visible: !!detail.sun && !!detail.sun.sunrise
                        Text { text: "日出日落"; color: "#80ffffff"; font.pixelSize: 12 }
                        Text { text: "日出 " + (detail.sun.sunrise || "--").slice(11, 16); color: "white"; font.pixelSize: 14 }
                        Text { text: "日落 " + (detail.sun.sunset || "--").slice(11, 16); color: "white"; font.pixelSize: 14 }
                    }

                    Rectangle { width: 1; height: 40; color: "#30ffffff" }

                    ColumnLayout {
                        spacing: 4
                        visible: !!detail.moon && !!detail.moon.moonPhase
                        Text { text: "月相"; color: "#80ffffff"; font.pixelSize: 12 }
                        RowLayout { spacing: 8
                            WeatherIcon { code: detail.moon.moonIcon || "800"; iconSize: 28; isDay: false }
                            ColumnLayout { spacing: 2
                                Text { text: detail.moon.moonPhase || ""; color: "white"; font.pixelSize: 14 }
                                Text { text: "亮度 " + (detail.moon.moonIllumination||"0") + "%"; color: "#ccffffff"; font.pixelSize: 11 }
                            }
                        }
                        RowLayout { spacing: 12
                            Text { text: "月出 " + (detail.moon.moonrise||"--").slice(11,16); color: "#aaffffff"; font.pixelSize: 11 }
                            Text { text: "月落 " + (detail.moon.moonset||"--").slice(11,16); color: "#aaffffff"; font.pixelSize: 11 }
                        }
                    }
                }
            }

            MouseArea {
                id: astroHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // ===== 卡片8: 太阳辐射 =====
        Rectangle {
            id: solarCard
            width: parent.width - parent.padding * 2
            height: solarContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: solarHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: !!detail.solar && detail.solar.ghi !== undefined

            ColumnLayout {
                id: solarContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 8

                Text { text: "太阳辐射"; color: "white"; font.pixelSize: 16; font.bold: true }

                Grid {
                    id: solarGrid
                    columns: 3; spacing: 8
                    Layout.fillWidth: true

                    Rectangle {
                        width: (solarCard.width - 24 - solarGrid.spacing * 2) / 3; height: 56; radius: 6
                        color: "#15ffffff"; border.width: 1; border.color: "#20ffffff"
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 2
                            Text { text: "GHI"; color: "#80ffffff"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                            Text { text: (detail.solar.ghi||"--") + " " + (detail.solar.ghiUnit||""); color: "white"; font.pixelSize: 14; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                    Rectangle {
                        width: (solarCard.width - 24 - solarGrid.spacing * 2) / 3; height: 56; radius: 6
                        color: "#15ffffff"; border.width: 1; border.color: "#20ffffff"
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 2
                            Text { text: "DNI"; color: "#80ffffff"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                            Text { text: (detail.solar.dni||"--") + " " + (detail.solar.dniUnit||""); color: "white"; font.pixelSize: 14; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                    Rectangle {
                        width: (solarCard.width - 24 - solarGrid.spacing * 2) / 3; height: 56; radius: 6
                        color: "#15ffffff"; border.width: 1; border.color: "#20ffffff"
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 2
                            Text { text: "DHI"; color: "#80ffffff"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                            Text { text: (detail.solar.dhi||"--") + " " + (detail.solar.dhiUnit||""); color: "white"; font.pixelSize: 14; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }

                RowLayout {
                    spacing: 16
                    Text { text: "太阳方位角: " + (detail.solar.solarAzimuth || "--") + "°"; color: "#aaffffff"; font.pixelSize: 12 }
                    Text { text: "太阳高度角: " + (detail.solar.solarElevation || "--") + "°"; color: "#aaffffff"; font.pixelSize: 12 }
                }
            }

            MouseArea {
                id: solarHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // ===== 卡片9: 分钟降水 =====
        Rectangle {
            id: minutelyCard
            width: parent.width - parent.padding * 2
            height: minutelyContent.implicitHeight + 24
            radius: 12
            color: "#20ffffff"
            border.width: 1
            border.color: minutelyHover.containsMouse ? "#50ffffff" : "#30ffffff"

            Behavior on border.color { ColorAnimation { duration: 200 } }
            visible: !!detail.minutely && !!detail.minutely.summary

            ColumnLayout {
                id: minutelyContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 12
                spacing: 6

                Text { text: "分钟级降水"; color: "white"; font.pixelSize: 16; font.bold: true }
                Text { text: detail.minutely.summary || ""; color: "#aaffffff"; font.pixelSize: 13; wrapMode: Text.WordWrap; Layout.fillWidth: true }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    contentWidth: precipRow.width
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    visible: !!detail.minutely.items && detail.minutely.items.length > 0

                    Row {
                        id: precipRow; spacing: 4
                        Repeater {
                            model: detail.minutely.items || []
                            Rectangle {
                                width: 50; height: 50; radius: 4
                                color: "#15ffffff"; border.width: 1; border.color: "#20ffffff"
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 1
                                    Text { text: modelData.fxTime ? modelData.fxTime.slice(11, 16) : ""; color: "#80ffffff"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: modelData.precip || "0"; color: "#64b5f6"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: "mm"; color: "#60ffffff"; font.pixelSize: 8; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: minutelyHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        // 底部留白
        Item { width: 1; height: 16 }
    }

    // ===== 辅助组件: 详情小标签 =====
    component DetailChip: Rectangle {
        property string label: ""
        property string value: ""
        height: 32; radius: 4
        color: "#15ffffff"
        border.width: 1; border.color: "#20ffffff"
        visible: value !== "" && value !== " "
        Row {
            anchors.centerIn: parent; spacing: 4
            Text { text: label; color: "#80ffffff"; font.pixelSize: 10 }
            Text { text: value; color: "white"; font.pixelSize: 11; font.bold: true }
        }
    }
}
