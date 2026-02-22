import SwiftUI
import SwiftData
import Combine

@MainActor
final class AppState: ObservableObject {
    let preferences = UserPreferences.shared

    // Core Services
    let storageService: StorageService
    let clipboardMonitor: ClipboardMonitor
    let shortcutManager: KeyboardShortcutManager
    let exclusionManager = ExclusionListManager()

    // Feature Services
    let transformService = TransformService.shared
    let snippetService: SnippetService
    let pasteStackManager = PasteStackManager()
    let ruleEngine: ClipboardRuleEngine
    let analyticsService: AnalyticsService
    let naturalLanguageSearch = NaturalLanguageSearchService.shared

    // UI State — Clipboard
    @Published var searchText: String = ""
    @Published var selectedCategory: CategoryFilter = .all
    @Published var clipboardItems: [ClipboardItem] = []
    @Published var selectedWorkspace: String? = nil

    // UI State — Diff
    @Published var diffSelection: [ClipboardItem] = []
    @Published var showDiffView: Bool = false

    // UI State — Merge
    @Published var mergeSelection: Set<UUID> = []
    @Published var showMergeView: Bool = false
    @Published var isMergeMode: Bool = false

    // UI State — Snippets
    @Published var snippets: [Snippet] = []
    @Published var snippetFolders: [SnippetFolder] = []

    // UI State — Transform Result
    @Published var transformResult: String? = nil
    @Published var showTransformResult: Bool = false

    // UI State — Item Detail / OCR (overlay-based, avoids MenuBarExtra .sheet() dismiss bug)
    @Published var detailItem: ClipboardItem? = nil
    @Published var ocrResultItem: ClipboardItem? = nil

    private var cancellables = Set<AnyCancellable>()

    init(modelContainer: ModelContainer) {
        let storage = StorageService(modelContainer: modelContainer)
        self.storageService = storage
        self.clipboardMonitor = ClipboardMonitor(
            storageService: storage,
            exclusionManager: exclusionManager
        )
        self.shortcutManager = KeyboardShortcutManager()
        self.snippetService = SnippetService(modelContainer: modelContainer)
        self.ruleEngine = ClipboardRuleEngine(modelContainer: modelContainer)
        self.analyticsService = AnalyticsService(modelContainer: modelContainer)

        // Wire up paste stack and rule engine to monitor
        clipboardMonitor.pasteStackManager = pasteStackManager
        clipboardMonitor.ruleEngine = ruleEngine

        // Start monitoring clipboard
        clipboardMonitor.startMonitoring()

        // Refresh UI when new item captured
        clipboardMonitor.onNewItem = { [weak self] in
            self?.refreshItems()
        }

        // Observe search and category changes with debounce
        $searchText
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .combineLatest($selectedCategory, $selectedWorkspace)
            .sink { [weak self] _, _, _ in
                self?.refreshItems()
            }
            .store(in: &cancellables)

        // Initial load
        refreshItems()

        // Seed built-in data and backfill embeddings for existing items
        Task {
            if !preferences.snippetsSeeded {
                await snippetService.seedBuiltInSnippets()
                await ruleEngine.seedDefaultRules()
                preferences.snippetsSeeded = true
            }
            await refreshSnippets()
            await storageService.backfillEmbeddings()
        }
    }

    // MARK: - Data Operations

    func refreshItems() {
        Task {
            let filter = selectedCategory.itemType
            let pinned = selectedCategory == .pinned

            let items: [ClipboardItem]
            if !searchText.isEmpty {
                let intent = naturalLanguageSearch.parseIntent(from: searchText)
                items = await storageService.fetchItems(
                    filterType: filter,
                    searchIntent: intent,
                    pinnedOnly: pinned,
                    workspaceName: selectedWorkspace
                )
            } else {
                items = await storageService.fetchItems(
                    filterType: filter,
                    searchText: "",
                    pinnedOnly: pinned
                )
            }

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

    func copyText(_ text: String) {
        clipboardMonitor.stopMonitoring()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
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

    // MARK: - Transform Operations

    func applyTransform(_ transform: any ClipboardTransform, to item: ClipboardItem) {
        guard let text = item.textContent else { return }
        let result = transformService.apply(transform, to: text)
        switch result {
        case .success(let transformed):
            transformResult = transformed
            showTransformResult = true
        case .failure:
            break
        }
    }

    // MARK: - OCR

    func extractTextFromImage(_ item: ClipboardItem) {
        guard let imageData = item.imageData else { return }
        Task {
            do {
                let text = try await OCRService.shared.extractText(from: imageData)
                if !text.isEmpty {
                    await storageService.updateOCRText(item.id, text: text)
                    refreshItems()
                }
            } catch {
                // OCR failed silently
            }
        }
    }

    // MARK: - Mask

    func toggleMask(_ item: ClipboardItem) {
        Task {
            await storageService.toggleMask(item.id)
            refreshItems()
        }
    }

    // MARK: - Diff

    func toggleDiffSelection(_ item: ClipboardItem) {
        if let index = diffSelection.firstIndex(where: { $0.id == item.id }) {
            diffSelection.remove(at: index)
        } else if diffSelection.count < 2 {
            diffSelection.append(item)
        }
        if diffSelection.count == 2 {
            showDiffView = true
        }
    }

    func clearDiffSelection() {
        diffSelection = []
        showDiffView = false
    }

    // MARK: - Merge

    func toggleMergeSelection(_ item: ClipboardItem) {
        if mergeSelection.contains(item.id) {
            mergeSelection.remove(item.id)
        } else {
            mergeSelection.insert(item.id)
        }
    }

    func clearMergeSelection() {
        mergeSelection = []
        isMergeMode = false
        showMergeView = false
    }

    var mergeSelectedItems: [ClipboardItem] {
        clipboardItems.filter { mergeSelection.contains($0.id) }
    }

    // MARK: - Snippets

    func refreshSnippets() async {
        let s = await snippetService.fetchSnippets()
        let f = await snippetService.fetchFolders()
        await MainActor.run {
            snippets = s
            snippetFolders = f
        }
    }

    func insertSnippet(_ snippet: Snippet, variables: [String: String]) {
        Task {
            let resolved = await snippetService.resolveTemplate(snippet, variables: variables)
            await snippetService.touchSnippet(snippet.id)
            await MainActor.run {
                copyText(resolved)
            }
        }
    }
}
