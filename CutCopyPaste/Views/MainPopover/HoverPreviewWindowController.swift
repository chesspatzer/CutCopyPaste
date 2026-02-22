import AppKit
import SwiftUI

/// Manages a borderless NSPanel that displays the hover preview to the left of the main popover.
@MainActor
final class HoverPreviewWindowController {
    private var panel: NSPanel?

    /// Show the preview panel to the left of the popover for the given item.
    func show(
        item: ClipboardItem,
        cardFrame: CGRect,
        popoverWindow: NSWindow,
        onHoverChange: @escaping (Bool) -> Void
    ) {
        let panelWidth = Constants.HoverPreview.panelWidth
        let minHeight: CGFloat = 80
        let gap: CGFloat = 6

        // Use screen's visible height (minus padding) instead of a fixed cap
        let screen = popoverWindow.screen ?? NSScreen.main
        let screenPadding: CGFloat = 16
        let maxHeight = (screen?.visibleFrame.height ?? 800) - screenPadding

        // Build SwiftUI content — fixedSize so it reports natural height
        let previewView = HoverPreviewPanel(
            item: item,
            cardFrame: cardFrame,
            popoverHeight: popoverWindow.frame.height,
            onHoverChange: onHoverChange
        )

        let hostingView = NSHostingView(rootView: previewView)

        // Measure natural content height
        hostingView.frame.size = NSSize(width: panelWidth, height: 10000)
        hostingView.layoutSubtreeIfNeeded()
        let naturalHeight = hostingView.fittingSize.height
        let panelHeight = min(max(naturalHeight, minHeight), maxHeight)
        let needsScroll = naturalHeight > maxHeight

        // Set up the content view — scrollable if content overflows
        let contentView: NSView
        if needsScroll {
            hostingView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: naturalHeight)

            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
            scrollView.documentView = hostingView
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.drawsBackground = false
            scrollView.scrollerStyle = .overlay
            contentView = scrollView
        } else {
            hostingView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
            contentView = hostingView
        }

        // Position: left of the popover, vertically aligned with the card
        let popoverFrame = popoverWindow.frame
        let panelX = popoverFrame.minX - panelWidth - gap

        // Convert card midY from popover's SwiftUI coordinate space (Y-down) to screen (Y-up)
        let cardMidYInScreen = popoverFrame.maxY - cardFrame.midY
        var panelY = cardMidYInScreen - panelHeight / 2

        // Clamp to screen bounds
        if let screen {
            let screenFrame = screen.visibleFrame
            panelY = max(screenFrame.minY + 8, min(panelY, screenFrame.maxY - panelHeight - 8))
        }

        let panelFrame = NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)

        if let existing = panel {
            existing.contentView = contentView
            existing.setFrame(panelFrame, display: true, animate: false)
            existing.appearance = popoverWindow.appearance
            if !existing.isVisible {
                existing.orderFront(nil)
            }
        } else {
            let p = NSPanel(
                contentRect: panelFrame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.level = popoverWindow.level + 1
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.isMovable = false
            p.hidesOnDeactivate = false
            p.becomesKeyOnlyIfNeeded = true
            p.contentView = contentView
            p.appearance = popoverWindow.appearance

            self.panel = p
            p.orderFront(nil)
        }
    }

    /// Hide the preview panel.
    func hide() {
        panel?.orderOut(nil)
    }

    /// Whether the panel is currently visible.
    var isVisible: Bool {
        panel?.isVisible ?? false
    }
}
