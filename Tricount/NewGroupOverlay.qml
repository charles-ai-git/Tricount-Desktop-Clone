import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: overlay
    anchors.fill: parent
    visible: false
    z: 100

    property var api: null

    function open() {
        // Reset du champ et focus à l'ouverture
        nameField.text = ""
        nameField.focus = false
        overlay.visible = true
        appearAnim.start()
    }

    function close() {
        disappearAnim.start()
    }

    // Gestion du fondu entrée/sortie
    OpacityAnimator {
        id: appearAnim
        target: overlay
        from: 0; to: 1
        duration: 180
        easing.type: Easing.OutCubic
    }
    OpacityAnimator {
        id: disappearAnim
        target: overlay
        from: 1; to: 0
        duration: 150
        easing.type: Easing.InCubic
        onFinished: overlay.visible = false
    }

    // Overlay d'arrière-plan
    Rectangle {
        anchors.fill: parent
        color: "#CC000000"

        MouseArea {
            anchors.fill: parent
            onClicked: overlay.close()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 440
        height: cardContent.implicitHeight + 48
        color: "#1C1C1E"
        radius: 16
        border.color: "#2C2C2C"
        border.width: 1

        // Consume les clics pour éviter de fermer l'overlay par erreur
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: cardContent
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 28
            }
            spacing: 0

            Label {
                text: "Nouveau Tricount"
                color: "#FFFFFF"
                font { pixelSize: 20; weight: Font.Bold }
                Layout.topMargin: 28
                Layout.bottomMargin: 24
            }

            Label {
                text: "Titre"
                color: "#FFFFFF"
                font { pixelSize: 14; weight: Font.Medium }
                Layout.bottomMargin: 8
            }

            // Input avec gestion du focus (bordure bleue)
            Rectangle {
                id: fieldContainer
                Layout.fillWidth: true
                height: 48
                radius: 10
                color: "#2C2C2E"
                border.color: nameField.activeFocus ? "#008CBE" : "#3A3A3C"
                border.width: nameField.activeFocus ? 2 : 1

                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on border.width { NumberAnimation { duration: 150 } }

                TextInput {
                    id: nameField
                    anchors {
                        fill: parent
                        leftMargin: 14; rightMargin: 14
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#FFFFFF"
                    font.pixelSize: 15
                    selectionColor: "#008CBE"
                    clip: true

                    // Shortcuts clavier standard
                    Keys.onReturnPressed: createBtn.clicked()
                    Keys.onEscapePressed: overlay.close()

                    Label {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Ex: Voyage à Rome..."
                        color: "#555555"
                        font.pixelSize: 15
                        visible: nameField.text.length === 0 && !nameField.activeFocus
                    }
                }
            }

            Item { Layout.fillWidth: true; height: 28 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Annuler
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: 12
                    color: cancelMouse.containsMouse ? "#2C2C2E" : "transparent"
                    border.color: "#3A3A3C"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Label {
                        anchors.centerIn: parent
                        text: "Annuler"
                        color: "#AAAAAA"
                        font { pixelSize: 15; weight: Font.Medium }
                    }
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: overlay.close()
                    }
                }

                // Bouton de validation
                Rectangle {
                    id: createBtn
                    Layout.fillWidth: true
                    height: 46
                    radius: 12
                    color: createMouse.containsMouse ? "#00A8E4" : "#008CBE"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    property bool isLoading: false
                    signal clicked()

                    onClicked: {
                        const name = nameField.text.trim()
                        if (name.length === 0) {
                            nameField.focus = true
                            return
                        }
                        createBtn.isLoading = true
                        overlay.api.createGroup(name)
                    }

                    Label {
                        anchors.centerIn: parent
                        text: createBtn.isLoading ? "Création..." : "Créer le tricount"
                        color: "#FFFFFF"
                        font { pixelSize: 15; weight: Font.Bold }
                    }
                    MouseArea {
                        id: createMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: createBtn.clicked()
                    }
                }
            }
        }
    }

    // Callbacks API
    Connections {
        target: overlay.api

        function onGroupCreated(groupId, groupName) {
            createBtn.isLoading = false
            overlay.close()
        }
        function onRequestFailed(errorMessage) {
            // On libère le bouton en cas d'erreur
            createBtn.isLoading = false
        }
    }
}
