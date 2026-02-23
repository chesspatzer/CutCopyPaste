import AppKit
import Carbon.HIToolbox
import os

final class KeyboardShortcutManager: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "Shortcuts")

    @Published var isRegistered: Bool = false
    @Published var needsAccessibilityPermission: Bool = false

    var onTogglePopover: (() -> Void)?

    func register() {
        guard !isRegistered else { return }

        #if APPSTORE
        // Sandbox-compatible: observe global key events (cannot consume them,
        // but Cmd+Shift+V has no conflicts in standard apps)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }

            let keyCode = Int(event.keyCode)
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])

            let prefs = UserPreferences.shared
            let targetKey = prefs.globalToggleKeyCode
            let storedFlags = UInt64(prefs.globalToggleModifiers)

            var targetNSFlags: NSEvent.ModifierFlags = []
            if storedFlags & CGEventFlags.maskCommand.rawValue != 0 { targetNSFlags.insert(.command) }
            if storedFlags & CGEventFlags.maskShift.rawValue != 0 { targetNSFlags.insert(.shift) }
            if storedFlags & CGEventFlags.maskAlternate.rawValue != 0 { targetNSFlags.insert(.option) }
            if storedFlags & CGEventFlags.maskControl.rawValue != 0 { targetNSFlags.insert(.control) }

            if keyCode == targetKey && flags == targetNSFlags {
                DispatchQueue.main.async {
                    self.onTogglePopover?()
                }
            }
        }
        isRegistered = true
        needsAccessibilityPermission = false
        logger.info("Global hotkey registered (sandbox mode)")
        #else
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
        #endif
    }

    func unregister() {
        #if APPSTORE
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        #else
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        #endif
        isRegistered = false
        logger.info("Global hotkey unregistered")
    }

    #if !APPSTORE
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    #endif

    deinit {
        unregister()
    }
}
