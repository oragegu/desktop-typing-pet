import AppKit

final class SettingsWindowController: NSWindowController {
    private let imageStore: ImageStore
    private let onChange: () -> Void
    private var sizePopup: NSPopUpButton!
    private var topCheckbox: NSButton!
    private var lockCheckbox: NSButton!
    private var launchAtLoginCheckbox: NSButton!

    init(imageStore: ImageStore, onChange: @escaping () -> Void) {
        self.imageStore = imageStore
        self.onChange = onChange
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 470, height: 470),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Typing Pet Settings"
        window.center()
        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { nil }

    func present() {
        syncControls()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])

        let title = NSTextField(labelWithString: "General")
        title.font = .boldSystemFont(ofSize: 15)
        root.addArrangedSubview(title)

        let sizeRow = NSStackView()
        sizeRow.orientation = .horizontal
        sizeRow.spacing = 12
        sizeRow.addArrangedSubview(NSTextField(labelWithString: "Pet size:"))
        sizePopup = NSPopUpButton()
        sizePopup.addItems(withTitles: PetSize.allCases.map(\.title))
        sizePopup.target = self
        sizePopup.action = #selector(generalChanged)
        sizeRow.addArrangedSubview(sizePopup)
        root.addArrangedSubview(sizeRow)

        topCheckbox = NSButton(checkboxWithTitle: "Keep pet above other windows", target: self, action: #selector(generalChanged))
        lockCheckbox = NSButton(checkboxWithTitle: "Lock position (clicks pass through the pet)", target: self, action: #selector(generalChanged))
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch Typing Pet when I log in", target: self, action: #selector(launchAtLoginChanged))
        root.addArrangedSubview(topCheckbox)
        root.addArrangedSubview(lockCheckbox)
        root.addArrangedSubview(launchAtLoginCheckbox)

        let separator = NSBox()
        separator.boxType = .separator
        root.addArrangedSubview(separator)
        separator.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true

        let imageTitle = NSTextField(labelWithString: "Images")
        imageTitle.font = .boldSystemFont(ofSize: 15)
        root.addArrangedSubview(imageTitle)

        for (index, image) in PetImage.allCases.enumerated() {
            let row = NSStackView()
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 8
            let label = NSTextField(labelWithString: image.displayName)
            label.widthAnchor.constraint(equalToConstant: 180).isActive = true
            let choose = NSButton(title: "Choose…", target: self, action: #selector(chooseImage(_:)))
            choose.tag = index
            let reset = NSButton(title: "Default", target: self, action: #selector(resetImage(_:)))
            reset.tag = index
            row.addArrangedSubview(label)
            row.addArrangedSubview(choose)
            row.addArrangedSubview(reset)
            root.addArrangedSubview(row)
        }

        let note = NSTextField(wrappingLabelWithString: "Typing Pet observes key-down events only to animate the pet. Keystrokes are not stored or transmitted.")
        note.textColor = .secondaryLabelColor
        note.maximumNumberOfLines = 2
        note.widthAnchor.constraint(equalToConstant: 420).isActive = true
        root.addArrangedSubview(note)
        syncControls()
    }

    private func syncControls() {
        sizePopup?.selectItem(at: AppPreferences.shared.petSize.rawValue)
        topCheckbox?.state = AppPreferences.shared.alwaysOnTop ? .on : .off
        lockCheckbox?.state = AppPreferences.shared.positionLocked ? .on : .off
        launchAtLoginCheckbox?.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
    }

    @objc private func generalChanged() {
        AppPreferences.shared.petSize = PetSize(rawValue: sizePopup.indexOfSelectedItem) ?? .normal
        AppPreferences.shared.alwaysOnTop = topCheckbox.state == .on
        AppPreferences.shared.positionLocked = lockCheckbox.state == .on
        onChange()
    }

    @objc private func launchAtLoginChanged() {
        do {
            try LaunchAtLoginManager.shared.setEnabled(launchAtLoginCheckbox.state == .on)
        } catch {
            syncControls()
            let alert = NSAlert()
            alert.messageText = "Couldn’t Change Login Setting"
            alert.informativeText = "Make sure Typing Pet is installed in Applications, then try again.\n\n\(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.beginSheetModal(for: window!)
        }
        onChange()
    }

    @objc private func chooseImage(_ sender: NSButton) {
        guard PetImage.allCases.indices.contains(sender.tag) else { return }
        let image = PetImage.allCases[sender.tag]
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif]
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: window!) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            var paths = AppPreferences.shared.imagePaths
            paths[image.rawValue] = url.path
            AppPreferences.shared.imagePaths = paths
            self?.imageStore.reload()
            self?.onChange()
        }
    }

    @objc private func resetImage(_ sender: NSButton) {
        guard PetImage.allCases.indices.contains(sender.tag) else { return }
        imageStore.reset(PetImage.allCases[sender.tag])
        onChange()
    }
}
