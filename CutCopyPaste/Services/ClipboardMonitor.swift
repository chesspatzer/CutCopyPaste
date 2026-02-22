import AppKit
import Combine
import os

final class ClipboardMonitor: ObservableObject {
    private let pasteboard = NSPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int
    private let storageService: StorageService
    private let exclusionManager: ExclusionListManager
    private let workspaceDetector = WorkspaceDetector()
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "ClipboardMonitor")

    @Published var isMonitoring: Bool = false

    /// Poll interval in seconds. 0.5s balances responsiveness vs CPU usage.
    /// NSPasteboard.changeCount is a simple integer comparison — negligible cost.
    private let pollInterval: TimeInterval = 0.5

    /// Callback fired when a new item is captured, for UI refresh.
    var onNewItem: (() -> Void)?

    /// Paste stack manager reference for multi-copy mode
    var pasteStackManager: PasteStackManager?

    /// Rule engine for auto-transforms
    var ruleEngine: ClipboardRuleEngine?

    init(storageService: StorageService, exclusionManager: ExclusionListManager) {
        self.storageService = storageService
        self.exclusionManager = exclusionManager
        self.lastChangeCount = pasteboard.changeCount
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = pasteboard.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        // Fire during UI tracking mode too (when popover is open)
        RunLoop.current.add(timer!, forMode: .common)
        logger.info("Clipboard monitoring started")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        logger.info("Clipboard monitoring stopped")
    }

    // MARK: - Change Detection

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Check source app exclusion
        let frontApp = NSWorkspace.shared.frontmostApplication
        let bundleID = frontApp?.bundleIdentifier
        if let bundleID, exclusionManager.isExcluded(bundleID: bundleID) {
            logger.debug("Skipping capture from excluded app: \(bundleID)")
            return
        }

        // Extract and store
        guard let item = extractClipboardContent() else { return }

        // Detect workspace context
        if let workspace = workspaceDetector.detectCurrentWorkspace() {
            item.workspacePath = workspace.path
            item.workspaceName = workspace.name
            item.workspaceType = workspace.type.rawValue
        }

        // Detect sensitive data
        if UserPreferences.shared.detectSensitiveData, let text = item.textContent {
            let matches = SensitiveDataDetector.shared.detect(in: text)
            if !matches.isEmpty {
                item.sensitiveDataTypes = matches.map(\.type.rawValue)
                if UserPreferences.shared.autoMaskSensitive {
                    item.isMasked = true
                }
            }
        }

        // Summarize long text
        if let text = item.textContent, TextSummarizer.shared.shouldSummarize(text) {
            item.summary = TextSummarizer.shared.summarize(text).oneLiner
        }

        Task {
            // Apply clipboard rules (auto-transforms)
            if let text = item.textContent, let ruleEngine {
                let transformed = await ruleEngine.applyRules(
                    to: text,
                    contentType: item.contentType,
                    sourceBundleID: bundleID
                )
                if transformed != text {
                    item.textContent = transformed
                    item.characterCount = transformed.count
                }
            }

            // Auto OCR for images
            if UserPreferences.shared.autoOCR,
               item.contentType == .image,
               let imageData = item.imageData {
                let text = try? await OCRService.shared.extractText(from: imageData)
                if let text, !text.isEmpty {
                    item.ocrText = text
                }
            }

            // Deduplication check
            if UserPreferences.shared.deduplicateConsecutive,
               await storageService.isDuplicateOfMostRecent(item.textContent, contentType: item.contentType) {
                await storageService.touchMostRecent()
                return
            }

            await storageService.save(item)

            // Push to paste stack if active
            await MainActor.run {
                if let pasteStackManager, pasteStackManager.isActive {
                    pasteStackManager.push(
                        textContent: item.textContent,
                        contentType: item.contentType
                    )
                }
                self.onNewItem?()
            }
        }
    }

    // MARK: - Content Extraction

    private func extractClipboardContent() -> ClipboardItem? {
        let frontApp = NSWorkspace.shared.frontmostApplication
        let bundleID = frontApp?.bundleIdentifier
        let appName = frontApp?.localizedName

        // 1. Files
        if let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !fileURLs.isEmpty {
            return ClipboardItem(
                contentType: .file,
                filePaths: fileURLs.map(\.path),
                sourceAppBundleID: bundleID,
                sourceAppName: appName
            )
        }

        // 2. Images
        if let image = NSImage(pasteboard: pasteboard),
           let tiff = image.tiffRepresentation {
            let bitmapRep = NSBitmapImageRep(data: tiff)
            let pngData = bitmapRep?.representation(using: .png, properties: [:])
            let thumbnail = image.resizedForThumbnail(maxSize: 64)

            return ClipboardItem(
                contentType: .image,
                imageData: pngData,
                thumbnailData: thumbnail,
                sourceAppBundleID: bundleID,
                sourceAppName: appName
            )
        }

        // 3. Rich text
        if let rtfData = pasteboard.data(forType: .rtf) {
            let plainText: String?
            if let attrString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                plainText = attrString.string
            } else {
                plainText = nil
            }

            return ClipboardItem(
                contentType: .richText,
                textContent: plainText,
                rtfData: rtfData,
                sourceAppBundleID: bundleID,
                sourceAppName: appName
            )
        }

        // 4. Plain text (also detect URLs)
        if let text = pasteboard.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let isLink = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")

            return ClipboardItem(
                contentType: isLink ? .link : .text,
                textContent: text,
                sourceAppBundleID: bundleID,
                sourceAppName: appName
            )
        }

        return nil
    }
}
