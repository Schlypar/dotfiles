pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "."

PanelWindow {
    id: root

    required property var bar
    property list<Notification> notifs
    property int maxNotifications: 7

    WlrLayershell.namespace: "shell:notifications"
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        left: true
        top: true
        bottom: true
        right: true
    }

    NotificationServer {
        actionsSupported: true

        onNotification: notif => {
            notif.tracked = true;
            
            // Create new array with the new notification
            let newNotifs = [...root.notifs];
            
            // If we've reached max capacity, remove the oldest one
            if (newNotifs.length >= root.maxNotifications) {
                // Remove the oldest notification (first in array)
                const oldestNotif = newNotifs.shift();
                // Manually dismiss the oldest notification
                if (oldestNotif) {
                    oldestNotif.dismiss();
                }
            }
            
            // Add the new notification
            newNotifs.push(notif);
            root.notifs = newNotifs;
        }
    }

    visible: stack.children.length != 0
    mask: Region {
        item: stack
    }

    ListView {
        id: stack

        model: ScriptModel {
            values: [...root.notifs]
        }
        anchors.right: parent.right
        y: root.bar.height
        implicitWidth: 240
        implicitHeight: children.reduce((h, c) => h + c.height, 0)
        interactive: false
        spacing: 20

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        move: Transition {
            NumberAnimation {
                property: "y"
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        remove: Transition {
            NumberAnimation {
                property: "y"
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        delegate: Notif {
            required property Notification modelData
            notif: modelData

            onDismissed: () => {
                // Manually dismiss the notification
                modelData.dismiss();
                // Remove from list
                const index = root.notifs.indexOf(notif);
                if (index > -1) {
                    let newNotifs = [...root.notifs];
                    newNotifs.splice(index, 1);
                    root.notifs = newNotifs;
                }
            }
        }
    }
}
