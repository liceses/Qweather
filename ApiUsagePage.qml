// ApiUsagePage.qml — API endpoint request counters / API 端点请求次数统计
import QtQuick
import QtQuick.Layouts

Item {
    id: page

    Flickable {
        anchors.fill: parent; anchors.margins: 24
        contentHeight: content.implicitHeight + 32
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 16

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "API 请求统计"
                color: "white"
                font.pixelSize: 28; font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "本次会话累计（重启清零）"
                color: "#80ffffff"
                font.pixelSize: 13
            }

            Grid {
                id: grid
                Layout.fillWidth: true
                columns: 2
                spacing: 8
                Layout.preferredWidth: parent.width

                Repeater {
                    model: weatherApi ? weatherApi.requestCounts() : null

                    Rectangle {
                        width: (grid.width - grid.spacing) / 2
                        height: 44; radius: 8
                        color: "#20ffffff"
                        border.width: 1; border.color: "#30ffffff"

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12
                            Text {
                                text: modelData.key
                                color: "#ccffffff"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.value
                                color: "white"
                                font.pixelSize: 16; font.bold: true
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                radius: 8
                color: resetBtn.containsMouse ? "#30ffffff" : "#15ffffff"
                border.width: 1; border.color: resetBtn.containsMouse ? "#50ffffff" : "#30ffffff"
                Layout.preferredWidth: resetText.implicitWidth + 32
                Layout.preferredHeight: 36
                Text {
                    id: resetText; anchors.centerIn: parent
                    text: "重置计数"; color: "white"; font.pixelSize: 13
                }
                MouseArea {
                    id: resetBtn; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Trigger page refresh by re-reading counts
                        page.forceActiveFocus()
                    }
                }
            }
        }
    }
}
