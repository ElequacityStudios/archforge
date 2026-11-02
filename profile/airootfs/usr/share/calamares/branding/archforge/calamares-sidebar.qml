import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick 2.3
import QtQuick.Layouts 1.3

Rectangle {
    color: Branding.styleString(Branding.SidebarBackground)
    height: 48
    width: parent.width

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: ViewManager

            delegate: Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: display
                    color: Branding.styleString(index === ViewManager.currentStepIndex ? Branding.SidebarTextCurrent : Branding.SidebarText)
                    font.pointSize: 9
                    font.bold: index === ViewManager.currentStepIndex
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: index === ViewManager.currentStepIndex ? 3 : 1
                    color: index === ViewManager.currentStepIndex ? Branding.styleString(Branding.SidebarBackgroundCurrent) : "#454b50"
                }
            }
        }
    }
}
