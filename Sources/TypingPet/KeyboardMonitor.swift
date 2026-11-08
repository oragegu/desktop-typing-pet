import AppKit
import CoreGraphics

private let keyboardEventCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard type == .keyDown, let userInfo else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    DispatchQueue.main.async {
        monitor.onKeyDown?(keyCode)
    }
    return Unmanaged.passUnretained(event)
}

final class KeyboardMonitor {
    var onKeyDown: ((UInt16) -> Void)?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var hasPermission: Bool { CGPreflightListenEventAccess() }
    var isRunning: Bool { eventTap != nil }

    @discardableResult
    func start() -> Bool {
        if isRunning { return true }
        guard hasPermission else { return false }

        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: keyboardEventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
    }

    deinit { stop() }
}
