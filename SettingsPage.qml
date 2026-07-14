import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property var weatherCache: null

    Flickable {
        anchors.fill: parent
        contentHeight: contentLayout.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentLayout
            width: Math.min(500, page.width * 0.8)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.max(12, page.height * 0.02)

            // 标题
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Math.max(12, page.height * 0.02)
                text: "设置"
                color: "white"
                font.pixelSize: Math.max(20, Math.min(28, page.width * 0.028))
                font.bold: true
            }

            // ===== 黑夜模式 =====
            Item {
                id: darkCard
                Layout.fillWidth: true
                property real margin: Math.max(12, page.width * 0.02)
                implicitHeight: darkInner.implicitHeight + margin * 2

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#20ffffff"
                    border.width: 1; border.color: "#30ffffff"
                }

                RowLayout {
                    id: darkInner
                    anchors.fill: parent
                    anchors.margins: darkCard.margin
                    spacing: 8

                    Text {
                        text: "黑夜模式"
                        color: "white"
                        font.pixelSize: Math.max(13, Math.min(16, page.width * 0.018))
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        id: darkToggle
                        property bool checked: appSettings ? appSettings.darkMode : true
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 24
                        radius: 12
                        color: darkToggle.checked ? "#4caf50" : "#40ffffff"
                        border.width: 1
                        border.color: darkToggle.checked ? "#4caf50" : "#30ffffff"

                        Rectangle {
                            id: darkKnob
                            x: darkToggle.checked ? 22 : 2
                            y: 2
                            width: 20; height: 20
                            radius: 10
                            color: "white"
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                darkToggle.checked = !darkToggle.checked
                                if (appSettings) appSettings.darkMode = darkToggle.checked
                            }
                        }
                    }
                }
            }

            // ===== 太阳辐射开关 =====
            Item {
                id: solarCard
                Layout.fillWidth: true
                property real margin: Math.max(12, page.width * 0.02)
                implicitHeight: solarInner.implicitHeight + margin * 2

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#20ffffff"
                    border.width: 1; border.color: "#30ffffff"
                }

                ColumnLayout {
                    id: solarInner
                    anchors.fill: parent
                    anchors.margins: solarCard.margin
                    spacing: Math.max(6, page.height * 0.01)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "太阳辐射显示"
                            color: "white"
                            font.pixelSize: Math.max(13, Math.min(16, page.width * 0.018))
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            id: solarToggle
                            property bool checked: appSettings ? appSettings.showSolarRadiation : true
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 24
                            radius: 12
                            color: solarToggle.checked ? "#4caf50" : "#40ffffff"
                            border.width: 1
                            border.color: solarToggle.checked ? "#4caf50" : "#30ffffff"

                            Rectangle {
                                id: knob
                                x: solarToggle.checked ? 22 : 2
                                y: 2
                                width: 20; height: 20
                                radius: 10
                                color: "white"
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    solarToggle.checked = !solarToggle.checked
                                    if (appSettings) appSettings.showSolarRadiation = solarToggle.checked
                                }
                            }
                        }
                    }

                    Text {
                        text: "关闭后仅显示日出日落和月相（和风天气太阳辐射API无免费额度）"
                        color: "#80ffffff"
                        font.pixelSize: Math.max(9, Math.min(11, page.width * 0.013))
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // ===== 缓存管理 =====
            Item {
                id: cacheCard
                Layout.fillWidth: true
                property real margin: Math.max(12, page.width * 0.02)
                implicitHeight: cacheInner.implicitHeight + margin * 2

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#20ffffff"
                    border.width: 1; border.color: "#30ffffff"
                }

                RowLayout {
                    id: cacheInner
                    anchors.fill: parent
                    anchors.margins: cacheCard.margin
                    spacing: 14

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: "缓存管理"
                            color: "white"
                            font.pixelSize: Math.max(13, Math.min(16, page.width * 0.018))
                        }
                        Text {
                            text: "清除所有本地缓存的天气数据"
                            color: "#80ffffff"
                            font.pixelSize: Math.max(9, Math.min(11, page.width * 0.013))
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignRight
                        radius: 8
                        color: clearBtn.hovered ? "#30ffffff" : "#15ffffff"
                        border.width: 1; border.color: clearBtn.hovered ? "#50ffffff" : "#30ffffff"
                        Layout.preferredWidth: clearText.implicitWidth + 24
                        Layout.preferredHeight: 32

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "清除"
                            color: "white"
                            font.pixelSize: Math.max(12, Math.min(14, page.width * 0.015))
                        }

                        MouseArea {
                            id: clearBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (page.weatherCache) page.weatherCache.clearAll()
                            }
                        }
                    }
                }
            }

            // ===== 版本 =====
            Item {
                id: versionCard
                Layout.fillWidth: true
                property real margin: Math.max(12, page.width * 0.02)
                implicitHeight: versionInner.implicitHeight + margin * 2

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#20ffffff"
                    border.width: 1; border.color: "#30ffffff"
                }

                RowLayout {
                    id: versionInner
                    anchors.fill: parent
                    anchors.margins: versionCard.margin
                    Text {
                        text: "版本"
                        color: "white"
                        font.pixelSize: Math.max(13, Math.min(16, page.width * 0.018))
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "v0.1"
                        color: "#80ffffff"
                        font.pixelSize: Math.max(13, Math.min(16, page.width * 0.018))
                    }
                }
            }

            // 数据来源
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "数据来源：和风天气"
                color: "#60ffffff"
                font.pixelSize: Math.max(9, Math.min(11, page.width * 0.013))
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
