import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: overlay
    anchors.fill: parent
    visible: false
    z: 100

    property var api: null
    property int groupId: -1
    property int userId: 1

    function open() {
        // Reset du formulaire à l'ouverture
        descField.text = ""
        amountField.text = ""
        dateField.text = Qt.formatDate(new Date(), "yyyy-MM-dd")
        overlay.visible = true
        appearAnim.start()
    }

    function close() { disappearAnim.start() }

    // Animations de transition (fondue)
    OpacityAnimator { id: appearAnim; target: overlay; from: 0; to: 1; duration: 180 }
    OpacityAnimator { id: disappearAnim; target: overlay; from: 1; to: 0; duration: 150; onFinished: overlay.visible = false }

    // Background sombre cliquable pour fermer l'overlay
    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
        MouseArea { anchors.fill: parent; onClicked: overlay.close() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 440
        height: cardContent.implicitHeight + 48
        color: "#1C1C1E"
        radius: 16
        border.color: "#2C2C2C"

        ColumnLayout {
            id: cardContent
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 28 }
            spacing: 16

            Label {
                text: "Ajouter une dépense"
                color: "#FFFFFF"
                font { pixelSize: 20; weight: Font.Bold }
                Layout.bottomMargin: 8
            }

            // --- Formulaire ---
            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Description"; color: "#FFFFFF"; font.pixelSize: 13 }
                Rectangle {
                    Layout.fillWidth: true; height: 44; color: "#2C2C2E"; radius: 8
                    TextInput {
                        id: descField
                        anchors.fill: parent; anchors.margins: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: "white"; clip: true

                        // Custom placeholder (visible seulement si vide et sans focus)
                        Text {
                            text: "Ex: Courses, Resto..."; color: "#555";
                            visible: !parent.text && !parent.activeFocus
                            anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label { text: "Montant (€)"; color: "#FFFFFF"; font.pixelSize: 13 }
                Rectangle {
                    Layout.fillWidth: true; height: 44; color: "#2C2C2E"; radius: 8
                    TextInput {
                        id: amountField
                        anchors.fill: parent; anchors.margins: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: "white"
                        validator: DoubleValidator { bottom: 0; decimals: 2 }
                    }
                }
            }

            Label {
                id: errorLabel
                color: "#FF453A"; font.pixelSize: 12; Layout.fillWidth: true
            }

            Button {
                id: saveBtn
                Layout.fillWidth: true
                text: "Enregistrer"
                onClicked: {
                    // Validation basique avant envoi
                    if (descField.text.trim() === "" || amountField.text === "") {
                        errorLabel.text = "Merci de remplir tous les champs";
                        return;
                    }
                    api.createExpense(overlay.groupId, overlay.userId, descField.text, parseFloat(amountField.text), dateField.text);
                }
            }
        }
    }

    Connections {
        target: overlay.api
        // On ferme dès que l'API confirme la création
        function onExpenseCreated() { overlay.close() }
    }
}
