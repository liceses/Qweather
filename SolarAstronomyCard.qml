import QtQuick
import QtQuick.Layouts

Item {
    id: card

    property string cityId: ""
    property string cityName: ""
    property var solarData: ({})

    Rectangle {
        anchors.fill: parent
        radius: Math.min(card.width, card.height) * 0.04
        color: "#20ffffff"
        border.width: 1; border.color: "#30ffffff"
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.max(6, Math.min(card.width, card.height) * 0.04)
            spacing: Math.max(2, card.height * 0.01)

            // 城市名
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: card.cityName || "--"
                color: "white"
                font.pixelSize: Math.max(13, Math.min(20, card.width * 0.065))
                font.bold: true
                elide: Text.ElideRight
                Layout.maximumWidth: card.width * 0.85
            }

            // GHI 大数字
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Text {
                    id: ghiText
                    text: card.solarData.ghi !== undefined ? card.solarData.ghi.toFixed(1) : "--"
                    color: "#ffd54f"
                    font.pixelSize: Math.max(28, Math.min(48, card.height * 0.18))
                    font.bold: true
                }
                Text {
                    text: card.solarData.ghiUnit || "W/m²"
                    color: "#aaffd54f"
                    font.pixelSize: Math.max(10, Math.min(14, card.width * 0.04))
                    anchors.bottom: ghiText.bottom
                    anchors.bottomMargin: ghiText.height * 0.15
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "总水平辐照度 (GHI)"
                color: "#60ffffff"
                font.pixelSize: Math.max(8, Math.min(11, card.width * 0.035))
            }

            // DNI / DHI 副行
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.max(12, card.width * 0.06)

                Column {
                    spacing: 1
                    Row {
                        spacing: 2
                        Text { text: "DNI"; color: "#80ffffff"; font.pixelSize: Math.max(8, Math.min(11, card.width * 0.035)) }
                        Text {
                            text: card.solarData.dni !== undefined ? card.solarData.dni.toFixed(1) : "--"
                            color: "#ffffff"; font.pixelSize: Math.max(9, Math.min(13, card.width * 0.04)); font.bold: true
                        }
                    }
                }
                Column {
                    spacing: 1
                    Row {
                        spacing: 2
                        Text { text: "DHI"; color: "#80ffffff"; font.pixelSize: Math.max(8, Math.min(11, card.width * 0.035)) }
                        Text {
                            text: card.solarData.dhi !== undefined ? card.solarData.dhi.toFixed(1) : "--"
                            color: "#ffffff"; font.pixelSize: Math.max(9, Math.min(13, card.width * 0.04)); font.bold: true
                        }
                    }
                }
            }

            // 分隔线
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.leftMargin: card.width * 0.05
                Layout.rightMargin: card.width * 0.05
                color: "#15ffffff"
            }

            // 日出日落
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.max(16, card.width * 0.08)
                visible: !!card.solarData.sunrise

                Column {
                    spacing: 1
                    Text { text: "日出"; color: "#80ffffff"; font.pixelSize: Math.max(8, Math.min(10, card.width * 0.032)); anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: card.solarData.sunrise ? card.solarData.sunrise.slice(11, 16) : "--:--"
                        color: "#ffcc80"; font.pixelSize: Math.max(11, Math.min(16, card.width * 0.05)); font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                Column {
                    spacing: 1
                    Text { text: "日落"; color: "#80ffffff"; font.pixelSize: Math.max(8, Math.min(10, card.width * 0.032)); anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: card.solarData.sunset ? card.solarData.sunset.slice(11, 16) : "--:--"
                        color: "#ff8a65"; font.pixelSize: Math.max(11, Math.min(16, card.width * 0.05)); font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // 月相
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                visible: !!card.solarData.moonPhase

                Text {
                    text: card.solarData.moonPhase || ""
                    color: "#c4e0ff"
                    font.pixelSize: Math.max(11, Math.min(16, card.width * 0.05))
                    font.bold: true
                }
                Text {
                    text: card.solarData.moonIllumination ? (card.solarData.moonIllumination + "%") : ""
                    color: "#80c4e0ff"
                    font.pixelSize: Math.max(9, Math.min(13, card.width * 0.04))
                    visible: text !== ""
                }
            }

            // 无数据提示
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "暂无天文数据"
                color: "#60ffffff"
                font.pixelSize: Math.max(10, Math.min(16, card.width * 0.05))
                visible: card.solarData.ghi === undefined && !card.solarData.sunrise && !card.solarData.moonPhase
            }
        }
    }
}
