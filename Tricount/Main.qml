import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Tricount 1.0

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    visible: true
    title: "Tricount Desktop"
    color: "#121212"

    // Instance unique pour tout le cycle de vie de l'app
    TricountApi { id: api }

    Row {
        anchors.fill: parent
        spacing: 0

        LeftPanel {
            id: sideBar
            width: 300; height: parent.height
            api: api
            onNewGroupRequested: newGroupOverlay.open()

            // Bordure de séparation verticale
            Rectangle {
                anchors.right: parent.right
                width: 1; height: parent.height
                color: "#252525"
            }
        }

        RightPanel {
            id: detailPanel
            width: parent.width - sideBar.width; height: parent.height
            api: api
            selectedGroupName: sideBar.selectedName
            selectedGroupId:   sideBar.selectedGroupId

            // Injection du contexte groupe/user pour la nouvelle dépense
            onAddExpenseRequested: {
                newExpenseOverlay.groupId = detailPanel.selectedGroupId
                newExpenseOverlay.userId  = detailPanel.currentUserId
                newExpenseOverlay.open()
            }
        }
    }

    // Overlays de création
    NewGroupOverlay {
        id: newGroupOverlay
        api: api
    }

    NewExpenseOverlay {
        id: newExpenseOverlay
        api: api
    }
}
