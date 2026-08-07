import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property var fileModelData
    property size sourceSize: Qt.size(0, 0)
    property color iconColor: Appearance.colors.colOnLayer1

    readonly property string symbol: {
        if (!fileModelData.fileIsDir) return "draft"

        switch (fileModelData.fileName.toLowerCase()) {
        case "documents": return "folder_special"
        case "downloads": return "download"
        case "music": return "library_music"
        case "pictures": return "photo_library"
        case "videos": return "video_library"
        default: return "folder"
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.symbol
        iconSize: Math.max(24, Math.min(root.width, root.height) * 0.45)
        color: root.iconColor
    }
}