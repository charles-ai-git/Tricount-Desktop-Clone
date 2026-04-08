import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: rightPanel
    color: "transparent"

    property string selectedGroupName: ""
    property int    selectedGroupId:   -1
    property int    currentUserId:     1
    property var    api

    // Notification pour l'overlay de saisie
    signal addExpenseRequested()

    QtObject {
        id: state
        property int currentTab: 0
    }

    ListModel {
        id: expenseModel
        property double totalAmount: 0.0
    }

    Connections {
        target: rightPanel.api

        function onExpensesLoaded(expenses, totalAmount) {
            expenseModel.clear()
            expenseModel.totalAmount = totalAmount

            // Logique pour insérer les headers de date dynamiquement
            var lastDate = ""
            for (var i = 0; i < expenses.length; i++) {
                var e = expenses[i]
                var showHeader = (e.date !== lastDate)

                expenseModel.append({
                    expense_id:   e.expense_id,
                    description:  e.description,
                    amount:        e.amount,
                    date:          e.date,
                    payer_id:      e.payer_id,
                    payer_name:    e.payer_name,
                    isDateHeader: showHeader,
                    headerDate:   showHeader ? e.date : ""
                })
                lastDate = e.date
            }
        }

        function onExpenseCreated(expenseId, description, amount) {
            // Rafraîchissement automatique après ajout
            rightPanel.api.loadExpenses(rightPanel.selectedGroupId)
        }
    }

    // Trigger de chargement au changement de groupe
    onSelectedGroupIdChanged: {
        if (selectedGroupId !== -1) {
            state.currentTab = 0
            api.loadExpenses(selectedGroupId)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 0

        Label {
            text: rightPanel.selectedGroupName || "Sélectionnez un groupe"
            font { pixelSize: 28; weight: Font.Bold }
            color: "#FFFFFF"
            Layout.bottomMargin: 24
        }

        // Switcher de vue (Dépenses / Équilibres)
        Rectangle {
            Layout.fillWidth: true
            height: 44; color: "#2C2C2E"; radius: 22
            Layout.bottomMargin: 24

            Row {
                anchors.fill: parent; anchors.margins: 4
                Rectangle {
                    width: parent.width / 2; height: parent.height; radius: 18
                    color: state.currentTab === 0 ? "#505054" : "transparent"
                    Label {
                        anchors.centerIn: parent; text: "Dépenses"
                        color: state.currentTab === 0 ? "#FFFFFF" : "#888888"
                        font { pixelSize: 14; weight: Font.Medium }
                    }
                    MouseArea { anchors.fill: parent; onClicked: state.currentTab = 0 }
                }
                Rectangle {
                    width: parent.width / 2; height: parent.height; radius: 18
                    color: state.currentTab === 1 ? "#505054" : "transparent"
                    Label {
                        anchors.centerIn: parent; text: "Balances"
                        color: state.currentTab === 1 ? "#FFFFFF" : "#888888"
                        font { pixelSize: 14; weight: Font.Medium }
                    }
                    MouseArea { anchors.fill: parent; onClicked: state.currentTab = 1 }
                }
            }
        }

        // Stats rapides
        Row {
            Layout.fillWidth: true; Layout.bottomMargin: 16
            visible: state.currentTab === 0; spacing: 0
            Column {
                width: parent.width / 2; spacing: 4
                Label { text: "Mes dépenses"; color: "#888888"; font.pixelSize: 13 }
                Label { text: "—"; color: "#FFFFFF"; font { pixelSize: 26; weight: Font.Bold } }
            }
            Column {
                width: parent.width / 2; spacing: 4
                Label { text: "Total du groupe"; color: "#888888"; font.pixelSize: 13 }
                Label { text: expenseModel.totalAmount.toFixed(2) + " €"; color: "#FFFFFF"; font { pixelSize: 26; weight: Font.Bold } }
            }
        }

        ExpensesView {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: state.currentTab === 0
            expenseModel:  expenseModel
            currentUserId: rightPanel.currentUserId
            api:           rightPanel.api
            groupId:       rightPanel.selectedGroupId
        }

        BalancesView {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: state.currentTab === 1
        }

        // Action principale
        Rectangle {
            Layout.fillWidth: true; height: 50; Layout.topMargin: 16
            visible: state.currentTab === 0
            radius: 25
            color: rightPanel.selectedGroupId !== -1
                   ? (addMouse.containsMouse ? "#00C8FF" : "#00AEEF")
                   : "#333333"

            Behavior on color { ColorAnimation { duration: 120 } }

            Label {
                anchors.centerIn: parent; text: "+ Ajouter une dépense"
                color: rightPanel.selectedGroupId !== -1 ? "#FFFFFF" : "#666666"
                font { pixelSize: 15; weight: Font.Bold }
            }
            MouseArea {
                id: addMouse
                anchors.fill: parent; hoverEnabled: true
                enabled: rightPanel.selectedGroupId !== -1
                onClicked: rightPanel.addExpenseRequested()
            }
        }
    }
}
