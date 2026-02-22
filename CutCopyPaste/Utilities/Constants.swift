import Foundation
import SwiftUI

enum Constants {
    static let appName = "CutCopyPaste"
    static let appBundleID = "com.cutcopypaste.app"

    enum Defaults {
        static let maxHistoryCount = 500
        static let retentionDays = 30
        static let pollInterval: TimeInterval = 0.5
        static let thumbnailMaxSize: CGFloat = 200
    }

    enum UI {
        static let popoverDefaultWidth: CGFloat = 400
        static let popoverDefaultHeight: CGFloat = 560
        static let cornerRadius: CGFloat = 12
        static let rowPaddingCompact: CGFloat = 10
        static let rowPaddingComfortable: CGFloat = 12
        static let cardShadowRadius: CGFloat = 3
        static let cardShadowOpacity: Double = 0.10
        static let cardSpacing: CGFloat = 6
    }

    enum Storage {
        static var storeURL: URL {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupport.appendingPathComponent("CutCopyPaste")
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
            return appDir.appendingPathComponent("CutCopyPaste.store")
        }
    }

    // MARK: - Typography
    // Rounded design for UI chrome, default for content
    enum Typography {
        // App title
        static let title = Font.system(size: 15, weight: .semibold, design: .rounded)
        // Card content text preview
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        // Source app name, metadata labels
        static let caption = Font.system(size: 11, weight: .medium, design: .rounded)
        // Timestamps, char counts, type labels
        static let footnote = Font.system(size: 10, weight: .medium, design: .rounded)
        // Tiny badges, dots
        static let micro = Font.system(size: 9, weight: .semibold, design: .rounded)
        // Search field
        static let search = Font.system(size: 13.5, weight: .regular, design: .rounded)
        // Tab labels
        static let tab = Font.system(size: 11, weight: .medium, design: .rounded)
        static let tabSelected = Font.system(size: 11, weight: .semibold, design: .rounded)
        // Link domain
        static let linkDomain = Font.system(size: 12, weight: .semibold, design: .rounded)
        // Link path / URL
        static let linkDetail = Font.system(size: 11, weight: .regular, design: .default)
        // Favicon initial
        static let faviconInitial = Font.system(size: 13, weight: .bold, design: .rounded)
        // File count
        static let fileTitle = Font.system(size: 13, weight: .medium, design: .rounded)
        // Summary text
        static let summary = Font.system(size: 11, weight: .regular, design: .default)
        // Empty state title
        static let emptyTitle = Font.system(size: 14, weight: .semibold, design: .rounded)
        // Empty state subtitle
        static let emptySubtitle = Font.system(size: 12, weight: .regular, design: .rounded)
        // Workspace chip
        static let chip = Font.system(size: 10, weight: .medium, design: .rounded)
        // Bar labels (compare bar, merge bar)
        static let bar = Font.system(size: 11, weight: .medium, design: .rounded)
        // Footer
        static let footer = Font.system(size: 10, weight: .medium, design: .rounded)
    }

    enum Animation {
        static let snappy: SwiftUI.Animation = .snappy(duration: 0.15, extraBounce: 0.02)
        static let quick: SwiftUI.Animation = .spring(duration: 0.12, bounce: 0.08)
        static let smooth: SwiftUI.Animation = .smooth(duration: 0.18)
        static let bouncy: SwiftUI.Animation = .spring(duration: 0.2, bounce: 0.15)
        static let staggerDelay: Double = 0.015
    }
}
