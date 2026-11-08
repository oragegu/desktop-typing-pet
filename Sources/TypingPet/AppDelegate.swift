import AppKit
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let imageStore = ImageStore()
    private var petController: PetWindowController!
    private var settingsController: SettingsWindowController!
    private var statusItem: NSStatusItem!
    private let keyboardMonitor = KeyboardMonitor()
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        petController = PetWindowController(imageStore: imageStore)
        petController.contextMenuProvider = { [weak self] in self?.makeMenu() ?? NSMenu() }
        settingsController = SettingsWindowController(imageStore: imageStore) { [weak self] in
            self?.petController.applyPreferences()
            self?.petController.refreshImages()
            self?.refreshStatusMenu()
        }
        buildStatusItem()
        keyboardMonitor.onKeyDown = { [weak self] keyCode in
            self?.petController.react(to: keyCode)
        }
        petController.showWindow(nil)
        petController.window?.orderFrontRegardless()
        configureInputMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        keyboardMonitor.stop()
    }

    private func configureInputMonitoring() {
        if keyboardMonitor.start() {
            refreshStatusMenu()
            return
        }
        CGRequestListenEventAccess()
        showInputPermissionExplanation()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else { return }
            if self.keyboardMonitor.start() {
                timer.invalidate()
                self.permissionTimer = nil
                self.refreshStatusMenu()
            }
        }
    }

    private func showInputPermissionExplanation() {
        let alert = NSAlert()
        alert.messageText = "Allow Input Monitoring"
        alert.informativeText = "Typing Pet needs Input Monitoring permission to notice key-down events while you type in other apps. It never records or transmits what you type. Enable Typing Pet in Privacy & Security → Input Monitoring."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            openInputMonitoringSettings()
        }
    }

    private func openInputMonitoringSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
        NSWorkspace.shared.open(url)
    }

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Typing Pet")
        }
        refreshStatusMenu()
    }

    private func refreshStatusMenu() {
        statusItem?.menu = makeMenu()
    }

    fileprivate func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Typing Pet Settings…", action: #selector(showSettings), keyEquivalent: ",").target = self

        let sizeItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        let sizeMenu = NSMenu()
        for size in PetSize.allCases {
            let item = NSMenuItem(title: size.title, action: #selector(changeSize(_:)), keyEquivalent: "")
            item.target = self
            item.tag = size.rawValue
            item.state = AppPreferences.shared.petSize == size ? .on : .off
            sizeMenu.addItem(item)
        }
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let top = NSMenuItem(title: "Always on Top", action: #selector(toggleAlwaysOnTop), keyEquivalent: "")
        top.target = self
        top.state = AppPreferences.shared.alwaysOnTop ? .on : .off
        menu.addItem(top)

        let lock = NSMenuItem(title: "Lock Position", action: #selector(togglePositionLock), keyEquivalent: "")
        lock.target = self
        lock.state = AppPreferences.shared.positionLocked ? .on : .off
        menu.addItem(lock)

        let launchAtLogin = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        menu.addItem(launchAtLogin)

        menu.addItem(withTitle: "Reset Position", action: #selector(resetPosition), keyEquivalent: "").target = self
        menu.addItem(.separator())
        let inputTitle = keyboardMonitor.isRunning ? "Input Monitoring: Enabled" : "Enable Input Monitoring…"
        let input = NSMenuItem(title: inputTitle,
                               action: keyboardMonitor.isRunning ? nil : #selector(showInputMonitoringSettings),
                               keyEquivalent: "")
        input.target = self
        menu.addItem(input)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Typing Pet", action: #selector(quit), keyEquivalent: "q").target = self
        return menu
    }

    @objc private func showSettings() { settingsController.present() }

    @objc private func changeSize(_ sender: NSMenuItem) {
        AppPreferences.shared.petSize = PetSize(rawValue: sender.tag) ?? .normal
        petController.applyPreferences()
        refreshStatusMenu()
    }

    @objc private func toggleAlwaysOnTop() {
        AppPreferences.shared.alwaysOnTop.toggle()
        petController.applyPreferences()
        refreshStatusMenu()
    }

    @objc private func togglePositionLock() {
        AppPreferences.shared.positionLocked.toggle()
        petController.applyPreferences()
        refreshStatusMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLoginManager.shared.setEnabled(!LaunchAtLoginManager.shared.isEnabled)
        } catch {
            showLaunchAtLoginError(error)
        }
        refreshStatusMenu()
    }

    private func showLaunchAtLoginError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Couldn’t Change Login Setting"
        alert.informativeText = "Make sure Typing Pet is installed in Applications, then try again.\n\n\(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.runModal()
    }

    @objc private func resetPosition() { petController.resetPosition() }
    @objc private func showInputMonitoringSettings() { openInputMonitoringSettings() }
    @objc private func quit() { NSApp.terminate(nil) }
}
