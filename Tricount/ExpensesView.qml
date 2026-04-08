import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: expensesView

    property var  expenseModel: null
    property int  currentUserId: 1
    property var  api: null
    property int  groupId: -1

    ListView {
        id: expenseList
        anchors.fill: parent
        model: expensesView.expenseModel
        clip: true
        spacing: 10

        // Marges pour ne pas que les cartes touchent les bords du panel
        leftMargin: 16
        rightMargin: 16
        topMargin: 10
        bottomMargin: 20

        delegate: Column {
            width: expenseList.width - (expenseList.leftMargin + expenseList.rightMargin)
            spacing: 0

            // Header de section (Date) - n'apparaît que si c'est la première dépense du jour
            Label {
                id: dateHeader
                visible: model.isDateHeader
                width: parent.width
                text: {
                    try {
                        return Qt.formatDate(new Date(model.headerDate), "dd MMMM yyyy")
                    } catch(e) {
                        return model.headerDate
                    }
                }
                color: "#ADB5BD" // Un gris clair plus doux que le blanc pur
                font { pixelSize: 14; weight: Font.DemiBold; capitalisation: Font.AllUppercase }
                topPadding: index === 0 ? 10 : 20
                bottomPadding: 10
            }

            // Carte de la dépense
            Rectangle {
                width: parent.width
                height: 72
                color: "#1C1C1E"
                radius: 12
                border.color: "#2C2C2E"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    // Icône de catégorie ou placeholder
                    Rectangle {
                        width: 40; height: 40; radius: 10
                        color: "#2C2C2E"
                        Layout.alignment: Qt.AlignVCenter

                        Label {
                            anchors.centerIn: parent
                            text: "€"
                            color: "#00AEEF"
                            font { pixelSize: 18; bold: true }
                        }
                    }

                    // Infos : Description et Payer
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: model.description
                            color: "white"
                            font { pixelSize: 15; weight: Font.Medium }
                            elide: Text.ElideRight
                        }

                        Label {
                            text: "Payé par " + (model.payer_id === expensesView.currentUserId ? "moi" : model.payer_name)
                            color: "#6C757D"
                            font.pixelSize: 12
                        }
                    }

                    // Montant
                    Label {
                        text: Number(model.amount).toFixed(2) + " €"
                        color: "white"
                        font { pixelSize: 17; weight: Font.Bold }
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        // État vide
        Label {
            anchors.centerIn: parent
            visible: expensesView.expenseModel && expensesView.expenseModel.count === 0
            text: "Historique vide pour ce groupe"
            color: "#495057"
            font.pixelSize: 15
        }
    }
}
