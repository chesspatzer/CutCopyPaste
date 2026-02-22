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
        static let cardShadowRadius: CGFloat = 2
        static let cardShadowOpacity: Double = 0.06
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

    enum Animation {
        static let snappy: SwiftUI.Animation = .snappy(duration: 0.25, extraBounce: 0.05)
        static let quick: SwiftUI.Animation = .spring(duration: 0.2, bounce: 0.15)
        static let smooth: SwiftUI.Animation = .smooth(duration: 0.3)
        static let bouncy: SwiftUI.Animation = .spring(duration: 0.35, bounce: 0.25)
        static let staggerDelay: Double = 0.03
    }
}
