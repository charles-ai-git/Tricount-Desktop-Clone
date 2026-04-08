import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Tricount 1.0

Item {
    id: leftPanel

    // Props de sélection pour l'affichage principal
    property int    selectedIndex:   -1
    property string selectedName:    ""
    property int    selectedGroupId: -1
    property var    api

    // Prévient Main.qml qu'il faut ouvrir la popup de création
    signal newGroupRequested()

    Component.onCompleted: api.loadGroups()

    Connections {
        target: api

        function onGroupsLoaded(groups) {
            tricountModel.clear()
            for (var i = 0; i < groups.length; i++) {
                tricountModel.append({
                    name: groups[i].group_name,
                    group_id: groups[i].group_id
                })
            }

            // On sélectionne le premier par défaut si la liste n'est pas vide
            if (tricountModel.count > 0) {
                leftPanel.selectedIndex   = 0
                leftPanel.selectedName    = tricountModel.get(0).name
                leftPanel.selectedGroupId = tricountModel.get(0).group_id
            }
        }

        function onGroupCreated(groupId, groupName) {
            tricountModel.append({ name: groupName, group_id: groupId })

            // Focus direct sur le nouveau groupe créé
            leftPanel.selectedIndex   = tricountModel.count - 1
            leftPanel.selectedName    = groupName
            leftPanel.selectedGroupId = groupId
        }

        function onRequestFailed(errorMessage) {
            errorDialog.informativeText = errorMessage
            errorDialog.open()
        }
    }

    ListModel { id: tricountModel }

    Rectangle {
        anchors.fill: parent
        color: "#1A1A1A"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Zone titre
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "Tricounts"
                    font { pixelSize: 20; weight: Font.Bold }
                    color: "#FFFFFF"
                }
            }

            ListView {
                id: groupList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: tricountModel
                clip: true

                delegate: Rectangle {
                    width: groupList.width
                    height: 48
                    color: leftPanel.selectedIndex === index ? "#2C2C2E" : "transparent"

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        text: model.name
                        color: leftPanel.selectedIndex === index ? "#FFFFFF" : "#AAAAAA"
                        font.pixelSize: 15
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            leftPanel.selectedIndex   = index
                            leftPanel.selectedName    = model.name
                            leftPanel.selectedGroupId = model.group_id
                        }
                    }
                }
            }

            // Footer avec le bouton d'ajout
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 32
                    height: 40
                    radius: 8
                    color: newBtn.containsMouse ? "#00C8FF" : "#00AEEF"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Label {
                        anchors.centerIn: parent
                        text: "+ New Tricount"
                        color: "white"
                        font { pixelSize: 14; weight: Font.Medium }
                    }

                    MouseArea {
                        id: newBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: leftPanel.newGroupRequested()
                    }
                }
            }
        }
    }

    // Popup d'erreur générique
    Dialog {
        id: errorDialog
        title: "Erreur"
        anchors.centerIn: Overlay.overlay
        modal: true
        width: 320
        property alias informativeText: errLabel.text
        contentItem: Label {
            id: errLabel
            wrapMode: Text.WordWrap
            color: "#FF453A"
            padding: 12
        }
        standardButtons: Dialog.Ok
    }
}
