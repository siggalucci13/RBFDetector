import Cocoa

class SettingsWindowController: NSWindowController {
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

  

    @objc private func saveAction(_ sender: NSButton) {
        

        UserDefaults.standard.set(serverURLTextField.stringValue, forKey: "serverURL")

        self.close()
    }

    @objc private func cancelAction(_ sender: NSButton) {
        // Cancel action remains unchanged
    }

    func loadSettings() {
        // Extended to load the server URL setting

        let serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        serverURLTextField.stringValue = serverURL
    }

    override var windowNibName: NSNib.Name? {
        // Return the nib name if using Interface Builder
        return NSNib.Name("RBF Settings")
    }
}
