import AppKit
import QuartzCore

final class PetImageView: NSImageView {
    var contextMenuProvider: (() -> NSMenu)?

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        contextMenuProvider?()
    }
}

final class PetWindowController: NSWindowController, NSWindowDelegate {
    private let imageView = PetImageView()
    private let imageStore: ImageStore
    private var resetWorkItem: DispatchWorkItem?
    private var nextHandIsLeft = true
    var contextMenuProvider: (() -> NSMenu)? {
        didSet { imageView.contextMenuProvider = contextMenuProvider }
    }

    init(imageStore: ImageStore) {
        self.imageStore = imageStore
        let size = AppPreferences.shared.petSize.windowSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init(window: panel)
        configureWindow(panel)
        show(.basic)
        restorePositionOrReset()
    }

    required init?(coder: NSCoder) { nil }

    private func configureWindow(_ panel: NSPanel) {
        panel.delegate = self
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.level = AppPreferences.shared.alwaysOnTop ? .floating : .normal
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = AppPreferences.shared.positionLocked
        panel.contentView = imageView

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.wantsLayer = true
    }

    func react(to keyCode: UInt16) {
        switch keyCode {
        case 49: show(.pattern1) // Space
        case 36, 76: show(.pattern2) // Return / keypad Enter
        default:
            show(nextHandIsLeft ? .left : .right)
            nextHandIsLeft.toggle()
        }
        bounce()
        scheduleIdleImage()
    }

    func refreshImages() {
        imageStore.reload()
        show(.basic)
    }

    func applyPreferences() {
        guard let window else { return }
        let oldFrame = window.frame
        let newSize = AppPreferences.shared.petSize.windowSize
        window.setFrame(NSRect(x: oldFrame.minX, y: oldFrame.minY,
                               width: newSize.width, height: newSize.height), display: true)
        window.level = AppPreferences.shared.alwaysOnTop ? .floating : .normal
        window.ignoresMouseEvents = AppPreferences.shared.positionLocked
    }

    func resetPosition() {
        guard let window, let screen = preferredScreen() else { return }
        let visible = screen.visibleFrame
        let origin = NSPoint(x: visible.maxX - window.frame.width - 24,
                             y: visible.minY + 18)
        window.setFrameOrigin(origin)
        AppPreferences.shared.savedOrigin = origin
    }

    private func restorePositionOrReset() {
        guard let window else { return }
        if let origin = AppPreferences.shared.savedOrigin,
           NSScreen.screens.contains(where: { $0.visibleFrame.intersects(NSRect(origin: origin, size: window.frame.size)) }) {
            window.setFrameOrigin(origin)
        } else {
            resetPosition()
        }
    }

    private func preferredScreen() -> NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
    }

    private func show(_ petImage: PetImage) {
        imageView.image = imageStore.images[petImage] ?? imageStore.images[.basic]
    }

    private func scheduleIdleImage() {
        resetWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.show(.basic) }
        resetWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: work)
    }

    private func bounce() {
        guard let layer = imageView.layer else { return }
        layer.removeAnimation(forKey: "typing-bounce")
        let bounce = CAKeyframeAnimation(keyPath: "transform.translation.y")
        bounce.values = [0, 12, 0]
        bounce.keyTimes = [0, 0.35, 1]
        bounce.duration = 0.16
        bounce.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(bounce, forKey: "typing-bounce")
    }

    func windowDidMove(_ notification: Notification) {
        if let origin = window?.frame.origin {
            AppPreferences.shared.savedOrigin = origin
        }
    }
}
