import SwiftUI
import SwiftData
import Combine

@MainActor
final class AppState: ObservableObject {
    let preferences = UserPreferences.shared

    // Services
    let storageService: StorageService
    let clipboardMonitor: ClipboardMonitor
    let shortcutManager: KeyboardShortcutManager
    let exclusionManager = ExclusionListManager()

    // UI State
    @Published var searchText: String = ""
    @Published var selectedCategory: CategoryFilter = .all
    @Published var clipboardItems: [ClipboardItem] = []

    private var cancellables = Set<AnyCancellable>()

    init(modelContainer: ModelContainer) {
        let storage = StorageService(modelContainer: modelContainer)
        self.storageService = storage
        self.clipboardMonitor = ClipboardMonitor(
            storageService: storage,
            exclusionManager: exclusionManager
        )
        self.shortcutManager = KeyboardShortcutManager()

        // Start monitoring clipboard
        clipboardMonitor.startMonitoring()

        // Refresh UI when new item captured
        clipboardMonitor.onNewItem = { [weak self] in
            self?.refreshItems()
        }

        // Observe search and category changes with debounce
        $searchText
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .combineLatest($selectedCategory)
            .sink { [weak self] _, _ in
                self?.refreshItems()
            }
            .store(in: &cancellables)

        // Initial load
        refreshItems()
    }

    // MARK: - Data Operations

    func refreshItems() {
        Task {
            let filter = selectedCategory.itemType
            let pinned = selectedCategory == .pinned
            let items = await storageService.fetchItems(
                filterType: filter,
                searchText: searchText,
                pinnedOnly: pinned
            )
            await MainActor.run {
                self.clipboardItems = items
            }
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        // Temporarily stop monitoring to avoid re-capturing what we just pasted
        clipboardMonitor.stopMonitoring()

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .text, .link:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .richText:
            if let rtf = item.rtfData {
                pasteboard.setData(rtf, forType: .rtf)
            }
            // Also set plain text fallback
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData, let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        case .file:
            if let paths = item.filePaths {
                let urls = paths.compactMap { URL(fileURLWithPath: $0) as NSURL }
                pasteboard.writeObjects(urls)
            }
        }

        // Update usage stats
        Task {
            await storageService.touchItem(item.id)
        }

        // Resume monitoring after a brief delay to skip our own paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.clipboardMonitor.startMonitoring()
        }
    }

    func togglePin(_ item: ClipboardItem) {
        Task {
            await storageService.togglePin(item.id)
            refreshItems()
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        Task {
            await storageService.delete(item.id)
            refreshItems()
        }
    }

    func clearAll() {
        Task {
            await storageService.clearAll(keepPinned: true)
            refreshItems()
        }
    }

}
