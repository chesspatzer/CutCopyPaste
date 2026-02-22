import SwiftUI
import UniformTypeIdentifiers

struct TransferableClipboardData: Transferable, Sendable {
    let text: String?
    let rtfData: Data?
    let imageData: Data?
    let filePaths: [String]?
    let contentType: ClipboardItemType

    init(from item: ClipboardItem) {
        self.text = item.textContent
        self.rtfData = item.rtfData
        self.imageData = item.imageData
        self.filePaths = item.filePaths
        self.contentType = item.contentType
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .utf8PlainText) { data in
            if let text = data.text {
                return Data(text.utf8)
            } else if let filePaths = data.filePaths {
                return Data(filePaths.joined(separator: "\n").utf8)
            }
            return Data()
        }

        DataRepresentation(exportedContentType: .rtf) { data in
            if let rtfData = data.rtfData {
                return rtfData
            }
            if let text = data.text {
                return Data(text.utf8)
            }
            return Data()
        }

        DataRepresentation(exportedContentType: .png) { data in
            if let imageData = data.imageData {
                return imageData
            }
            return Data()
        }
    }
}
