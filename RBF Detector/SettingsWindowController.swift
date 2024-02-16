import Cocoa

class SettingsWindowController: NSWindowController {
    private var intervalTextField: NSTextField!
    private var directoryTextField: NSTextField!
    private var serverURLTextField: NSTextField! // New server URL text field
    private var chooseButton: NSButton!
    private var saveButton: NSButton!
    private var cancelButton: NSButton!
    weak var appDelegate: AppDelegate?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "Settings"
        super.init(window: window)
        self.window = window
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupUI()
    }

    private func setupUI() {
        guard let window = self.window else { return }

        // Interval TextField setup
        let verticalSpacing: CGFloat = 10 // Spacing between elements
        let labelHeight: CGFloat = 20
        let inputFieldHeight: CGFloat = 24
        var yOffset = window.frame.size.height - 80 // Starting y-offset for the first element

        // Adjust the window height if necessary
        // window.setContentSize(NSSize(width: window.frame.size.width, height: 480)) // Example adjustment

        // Interval Label
        let intervalLabel = NSTextField(frame: NSRect(x: 20, y: yOffset, width: 200, height: labelHeight))
        intervalLabel.stringValue = "Interval (seconds):"
        intervalLabel.isBezeled = false
        intervalLabel.drawsBackground = false
        intervalLabel.isEditable = false
        intervalLabel.isSelectable = false
        window.contentView?.addSubview(intervalLabel)
        yOffset -= (labelHeight + verticalSpacing)

        // Interval TextField setup
        intervalTextField = NSTextField(frame: NSRect(x: 20, y: yOffset, width: 200, height: inputFieldHeight))
        window.contentView?.addSubview(intervalTextField)
        yOffset -= (inputFieldHeight + verticalSpacing * 2) // Increase spacing before next section

        // Directory Label
        let directoryLabel = NSTextField(frame: NSRect(x: 20, y: yOffset, width: 280, height: labelHeight))
        directoryLabel.stringValue = "Save photos directory:"
        directoryLabel.isBezeled = false
        directoryLabel.drawsBackground = false
        directoryLabel.isEditable = false
        directoryLabel.isSelectable = false
        window.contentView?.addSubview(directoryLabel)
        yOffset -= (labelHeight + verticalSpacing)

        // Directory TextField setup
        directoryTextField = NSTextField(frame: NSRect(x: 20, y: yOffset, width: 280, height: inputFieldHeight))
        directoryTextField.isEditable = false
        window.contentView?.addSubview(directoryTextField)
        yOffset -= (inputFieldHeight + verticalSpacing * 2) // Increase spacing before next section

        // Server URL Label
        let serverURLLabel = NSTextField(frame: NSRect(x: 20, y: yOffset, width: 280, height: labelHeight))
        serverURLLabel.stringValue = "Server URL (ex: https://localhost:11434):"
        serverURLLabel.isBezeled = false
        serverURLLabel.drawsBackground = false
        serverURLLabel.isEditable = false
        serverURLLabel.isSelectable = false
        window.contentView?.addSubview(serverURLLabel)
        yOffset -= (labelHeight + verticalSpacing)

        // Server URL TextField setup
        serverURLTextField = NSTextField(frame: NSRect(x: 20, y: yOffset, width: 280, height: inputFieldHeight))
        window.contentView?.addSubview(serverURLTextField)

        // Choose Button setup
        let chooseButtonYPosition = directoryTextField.frame.origin.y // Use the directoryTextField's y position for alignment

        // Choose Button setup
        chooseButton = NSButton(frame: NSRect(x: 310, y: chooseButtonYPosition, width: 80, height: 24))
        chooseButton.title = "Choose..."
        chooseButton.bezelStyle = .rounded
        chooseButton.target = self
        chooseButton.action = #selector(chooseDirectoryAction(_:))
        window.contentView?.addSubview(chooseButton)

        // Save Button setup
        saveButton = NSButton(frame: NSRect(x: 220, y: 20, width: 80, height: 24))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveAction(_:))
        window.contentView?.addSubview(saveButton)

        // Cancel Button setup
        cancelButton = NSButton(frame: NSRect(x: 310, y: 20, width: 80, height: 24))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelAction(_:))
        window.contentView?.addSubview(cancelButton)

        loadSettings()
    }

    @objc private func chooseDirectoryAction(_ sender: NSButton) {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.begin { [weak self] result in
                guard let self = self, result == .OK, let url = panel.url else { return }
                
                self.directoryTextField.stringValue = url.path // Update the text field to show the chosen directory.
                self.appDelegate?.updateSaveDirectoryURL(url) // Update the save directory URL in the AppDelegate.
            }
        }

    @objc private func saveAction(_ sender: NSButton) {
        // Extended to save the server URL setting
        if let interval = Double(intervalTextField.stringValue) {
            UserDefaults.standard.set(interval, forKey: "captureInterval")
        }
        
        if let directoryPath = URL(string: directoryTextField.stringValue) {
            UserDefaults.standard.set(directoryPath.path, forKey: "saveDirectoryPath")
        }

        UserDefaults.standard.set(serverURLTextField.stringValue, forKey: "serverURL")

        self.close()
    }

    @objc private func cancelAction(_ sender: NSButton) {
        // Cancel action remains unchanged
    }

    func loadSettings() {
        // Extended to load the server URL setting
        guard let _ = self.window, intervalTextField != nil, directoryTextField != nil, serverURLTextField != nil else {
            return
        }

        let interval = UserDefaults.standard.double(forKey: "captureInterval")
        if interval > 0 {
            intervalTextField.stringValue = String(interval)
        }

        let directoryPath = UserDefaults.standard.string(forKey: "saveDirectoryPath") ?? ""
        directoryTextField.stringValue = directoryPath

        let serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        serverURLTextField.stringValue = serverURL
    }

    override var windowNibName: NSNib.Name? {
        // Return the nib name if using Interface Builder
        return NSNib.Name("RBF Settings")
    }
}
