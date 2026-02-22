import Foundation
import SwiftUI

enum Constants {
    static let appName = "CutCopyPaste"
    static let appBundleID = "com.cutcopypaste.app"

    enum Defaults {
        static let maxHistoryCount = 500
        static let retentionDays = 30
        static let pollInterval: TimeInterval = 0.5
        static let thumbnailMaxSize: CGFloat = 64
    }

    enum UI {
        static let popoverDefaultWidth: CGFloat = 360
        static let popoverDefaultHeight: CGFloat = 520
        static let cornerRadius: CGFloat = 10
        static let rowPaddingCompact: CGFloat = 8
        static let rowPaddingComfortable: CGFloat = 11
    }

    enum Animation {
        static let snappy: SwiftUI.Animation = .snappy(duration: 0.25, extraBounce: 0.05)
        static let quick: SwiftUI.Animation = .spring(duration: 0.2, bounce: 0.15)
        static let smooth: SwiftUI.Animation = .smooth(duration: 0.3)
        static let bouncy: SwiftUI.Animation = .spring(duration: 0.35, bounce: 0.25)
        static let staggerDelay: Double = 0.03
    }
}
