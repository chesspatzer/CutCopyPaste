import AppKit
import Carbon.HIToolbox
import os

final class KeyboardShortcutManager: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "Shortcuts")

    @Published var isRegistered: Bool = false
    @Published var needsAccessibilityPermission: Bool = false

    var onTogglePopover: (() -> Void)?

    func register() {
        guard !isRegistered else { return }

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { _, _, event, refcon in
            guard let refcon else { return Unmanaged.passRetained(event) }
            let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(refcon).takeUnretainedValue()

            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags

            let prefs = UserPreferences.shared
            let targetKey = Int64(prefs.globalToggleKeyCode)
            let targetFlags = CGEventFlags(rawValue: UInt64(prefs.globalToggleModifiers))

            let relevantFlags = flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])

            if keyCode == targetKey && relevantFlags == targetFlags {
                DispatchQueue.main.async {
                    manager.onTogglePopover?()
                }
                return nil // Consume the event
            }

            return Unmanaged.passRetained(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: refcon
        ) else {
            logger.warning("Failed to create event tap — Accessibility permission likely not granted")
            needsAccessibilityPermission = true
            return
        }

        self.eventTap = tap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRegistered = true
        needsAccessibilityPermission = false
        logger.info("Global hotkey registered")
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isRegistered = false
        logger.info("Global hotkey unregistered")
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    deinit {
        unregister()
    }
}
