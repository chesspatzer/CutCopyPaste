import Foundation
import SwiftUI

@MainActor
final class PasteStackManager: ObservableObject {
    enum PasteMode: String, CaseIterable {
        case stack  // LIFO
        case queue  // FIFO

        var displayName: String {
            switch self {
            case .stack: return "Stack (LIFO)"
            case .queue: return "Queue (FIFO)"
            }
        }
    }

    @Published var items: [PasteStackItem] = []
    @Published var isActive: Bool = false
    @Published var pasteMode: PasteMode {
        didSet { UserPreferences.shared.pasteStackMode = pasteMode.rawValue }
    }

    init() {
        self.pasteMode = PasteMode(rawValue: UserPreferences.shared.pasteStackMode) ?? .queue
    }

    var depth: Int { items.count }
    var isEmpty: Bool { items.isEmpty }

    struct PasteStackItem: Identifiable {
        let id = UUID()
        let textContent: String?
        let contentType: ClipboardItemType
        let preview: String
    }

    func activate() {
        isActive = true
        items = []
    }

    func deactivate() {
        isActive = false
        items = []
    }

    func push(textContent: String?, contentType: ClipboardItemType) {
        let preview: String
        if let text = textContent {
            preview = String(text.prefix(80))
        } else {
            preview = contentType.displayName
        }
        items.append(PasteStackItem(
            textContent: textContent,
            contentType: contentType,
            preview: preview
        ))
    }

    func pasteNext() -> PasteStackItem? {
        guard !items.isEmpty else { return nil }
        switch pasteMode {
        case .queue: return items.removeFirst()
        case .stack: return items.removeLast()
        }
    }

    func clearStack() {
        items = []
    }

    func toggleMode() {
        pasteMode = pasteMode == .queue ? .stack : .queue
    }
}
