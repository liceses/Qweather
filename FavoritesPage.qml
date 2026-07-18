// FavoritesPage.qml — Favorites list with pin-to-sidebar functionality
// 收藏页 — 收藏城市卡片列表，支持固定到侧边栏
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    // [EN] Favorites list, pinned list, weather data map / [CN] 收藏列表、固定列表、天气数据映射
    property var favorites: []
    property var pinned: []
    property var weathers: ({})

    // [EN] Signals: single click, double click, pin toggle / [CN] 单击、双击、固定切换信号
    signal cityClicked(string cityId)
    signal cityDoubleClicked(string cityId)
    signal pinToggled(var cityObj)

    Flickable {
        anchors.fill: parent
        anchors.margins: 40
        clip: true
        contentHeight: contentColumn.implicitHeight + 32
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 12

            Text {
                text: "收藏城市"
                color: "white"
                font.pixelSize: 28
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "暂无收藏城市\n在城市详情页点击星标即可收藏"
                color: "#60ffffff"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.6
                visible: page.favorites.length === 0
                Layout.topMargin: 60
            }

            Repeater {
                model: page.favorites
                delegate: Rectangle {
                    id: card
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: 12
                    color: hoverArea.containsMouse ? "#25ffffff" : "#20ffffff"
                    border.width: 1
                    border.color: hoverArea.containsMouse ? "#50ffffff" : "#30ffffff"

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    property var wdata: page.weathers[modelData.id] || ({})
                    property bool isPinned: {
                        let p = page.pinned
                        for (let i = 0; i < p.length; i++) {
                            if (p[i].id === modelData.id) return true
                        }
                        return false
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        WeatherIcon {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            Layout.alignment: Qt.AlignVCenter
                            code: card.wdata.icon || "100"
                            iconSize: 36
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            Text {
                                text: modelData.name || modelData.id
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: card.wdata.text || ""
                                color: "#80ffffff"
                                font.pixelSize: 12
                                visible: text !== ""
                            }
                        }

                        Text {
                            Layout.preferredWidth: 50
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            text: card.wdata.temp ? card.wdata.temp + "\u00b0" : "--\u00b0"
                            color: "white"
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignVCenter
                            radius: 8
                            color: pinMouse.containsMouse ? "#35000000" : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: card.isPinned ? "\uD83D\uDCCC" : "\uD83D\uDCCD"
                                font.pixelSize: 14
                                color: card.isPinned ? "#4caf50" : "#80ffffff"
                            }
                            MouseArea {
                                id: pinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.pinToggled(modelData)
                            }
                        }
                    }

                    property var _lastClick: 0
                    Timer {
                        id: clickTimer
                        interval: 400
                        onTriggered: {
                            page.cityClicked(modelData.id)
                            card._lastClick = 0
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        z: -1

                        onClicked: function(mouse) {
                            var now = Date.now()
                            if (now - card._lastClick < 400) {
                                clickTimer.stop()
                                card._lastClick = 0
                                page.cityDoubleClicked(modelData.id)
                            } else {
                                card._lastClick = now
                                clickTimer.restart()
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 16; visible: page.favorites.length > 0 }
        }
    }
}
