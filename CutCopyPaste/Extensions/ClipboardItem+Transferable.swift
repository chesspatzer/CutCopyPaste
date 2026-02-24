import SwiftUI
import UniformTypeIdentifiers

struct TransferableClipboardData: Transferable, Sendable {
    // Only store lightweight fields eagerly. External-storage blobs
    // (rtfData, imageData) are captured lazily via closures so that
    // scrolling through the list doesn't trigger disk I/O per row.
    let text: String?
    let filePaths: [String]?
    let contentType: ClipboardItemType
    private let _rtfData: @Sendable () -> Data?
    private let _imageData: @Sendable () -> Data?

    var rtfData: Data? { _rtfData() }
    var imageData: Data? { _imageData() }

    init(from item: ClipboardItem) {
        self.text = item.textContent
        self.filePaths = item.filePaths
        self.contentType = item.contentType
        // Capture the item weakly — blobs are only read when a drag
        // actually starts, not when the row appears during scroll.
        let itemID = item.id
        self._rtfData = { [weak item] in item?.rtfData }
        self._imageData = { [weak item] in item?.imageData }
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
