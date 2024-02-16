import Cocoa

class SettingsWindowController: NSWindowController {
    private var intervalTextField: NSTextField!
    private var directoryTextField: NSTextField!
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
            super.init(window: window) // Call the designated initializer here
            self.window = window
            setupUI() // Call the designated initializer here
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func windowDidLoad() {
            super.windowDidLoad()
            setupUI() // Your setupUI method to configure the window's content
        }
        
    
    private func setupUI() {
        guard let window = self.window else { return }

        // Interval TextField setup
        intervalTextField = NSTextField(frame: NSRect(x: 20, y: window.frame.size.height - 60, width: 200, height: 24))
        intervalTextField.placeholderString = "Interval (seconds)"
        window.contentView?.addSubview(intervalTextField)

        // Directory TextField setup
        directoryTextField = NSTextField(frame: NSRect(x: 20, y: window.frame.size.height - 100, width: 280, height: 24))
        directoryTextField.placeholderString = "Save photos directory"
        directoryTextField.isEditable = false
        window.contentView?.addSubview(directoryTextField)

        // Choose Button setup
        chooseButton = NSButton(frame: NSRect(x: 310, y: window.frame.size.height - 102, width: 80, height: 24))
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
        // Here, you would save the interval and directory settings
        // For example, using UserDefaults:
        if let interval = Double(intervalTextField.stringValue) {
            UserDefaults.standard.set(interval, forKey: "captureInterval")
        }
        
        if let directoryPath = URL(string: directoryTextField.stringValue) {
            UserDefaults.standard.set(directoryPath.path, forKey: "saveDirectoryPath")
        }
        
        // Close the window after saving
        self.close()
    }
    
    @objc private func cancelAction(_ sender: NSButton) {
        // Simply close the window without saving
        self.close()
    }
    
    // Additional methods to load saved settings into the UI elements when the window opens
    func loadSettings() {
        // Guard to ensure UI elements are initialized
        guard let _ = self.window, intervalTextField != nil, directoryTextField != nil else {
            return
        }

        // Proceed to load and apply settings to UI elements
        let interval = UserDefaults.standard.double(forKey: "captureInterval")
        if interval > 0 {
            intervalTextField.stringValue = String(interval)
        }

        let directoryPath = UserDefaults.standard.string(forKey: "saveDirectoryPath") ?? ""
        directoryTextField.stringValue = directoryPath
    }

    
    override var windowNibName: NSNib.Name? {
        // Return the nib name here if using Interface Builder
        return NSNib.Name("YourNibName")
    }
}
