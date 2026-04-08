import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: balancesView

    // Le modèle sera injecté depuis le C++ ou le parent
    property var balanceModel: ListModel {}

    ListView {
        id: listView
        anchors.fill: parent
        model: balancesView.balanceModel
        clip: true
        spacing: 10 // Un peu plus d'air entre les cartes

        // Un petit padding en haut pour ne pas coller au bord
        topMargin: 10
        leftMargin: 10
        rightMargin: 10

        delegate: Rectangle {
            // Calcul de largeur dynamique pour s'adapter à la liste
            width: listView.width - (listView.leftMargin + listView.rightMargin)
            height: 70
            color: "#1C1C1E"
            radius: 10
            border.color: "#333333"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 15

                // Avatar circulaire : Initial du nom
                Rectangle {
                    width: 40; height: 40
                    radius: 20
                    Layout.alignment: Qt.AlignVCenter
                    color: model.amount >= 0 ? "#1A3D2B" : "#3D1A1A"

                    Label {
                        anchors.centerIn: parent
                        text: model.name ? model.name.charAt(0).toUpperCase() : "?"
                        color: model.amount >= 0 ? "#4CAF50" : "#F44336"
                        font { pixelSize: 16; bold: true }
                    }
                }

                // Infos texte : Nom et statut
                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Label {
                        text: model.name
                        color: "white"
                        font { pixelSize: 15; weight: Font.Medium }
                    }
                    Label {
                        text: model.amount >= 0 ? "doit recevoir" : "doit rembourser"
                        color: "#999999"
                        font.pixelSize: 12
                    }
                }

                // Montant final
                Label {
                    Layout.alignment: Qt.AlignVCenter
                    text: (model.amount >= 0 ? "+" : "") + Number(model.amount).toFixed(2) + " €"
                    color: model.amount >= 0 ? "#4CAF50" : "#F44336"
                    font { pixelSize: 16; bold: true }
                }
            }
        }

        // Placeholder si la liste est vide
        Label {
            anchors.centerIn: parent
            visible: listView.count === 0
            text: "Aucune balance disponible"
            color: "#666666"
            font.pixelSize: 14
        }
    }
}
