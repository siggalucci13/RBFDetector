import Cocoa
import AVFoundation
import Foundation

@main
class AppDelegate: NSObject, NSApplicationDelegate, AVCapturePhotoCaptureDelegate {
    var settingsWindowController: SettingsWindowController?
    var statusBarItem: NSStatusItem!
    var captureSession: AVCaptureSession?
    var photoOutput = AVCapturePhotoOutput()
    var timer: Timer?
    var saveDirectoryURL: URL?

    var isCapturing = false // Track the capturing state
    var menu: NSMenu!
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "MenuIconMain") // Make sure "MenuIcon" is the exact name of your image asset
            button.action = #selector(statusBarButtonClicked(_:))
        }

        
        self.menu = NSMenu()
        
        // Setup menu items
        self.menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettingsWindow), keyEquivalent: "s"))
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: "Toggle Capture", action: #selector(toggleCapture), keyEquivalent: "t"))
        self.menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        self.statusBarItem.menu = self.menu
        
        // Initialize capture session
        setupCaptureSession()
    }
    
    @objc func statusBarButtonClicked(_ sender: Any?) {
        // This could potentially be used for another feature.
    }
    
    @objc func toggleCapture() {
        isCapturing.toggle()
        if isCapturing {
            print("Capturing")
            let interval = UserDefaults.standard.double(forKey: "captureInterval") ?? 10.0
            startTimer(interval: interval)
        } else {
            timer?.invalidate()
        }
        
        // Update the toggle menu item title based on the capturing state
        if let item = statusBarItem.menu?.items.first(where: { $0.action == #selector(toggleCapture) }) {
            item.title = isCapturing ? "Stop Capture" : "Start Capture"
        }
    }
    
    @objc func showSettingsWindow() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
            settingsWindowController?.appDelegate = self
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setupCaptureSession() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraAuthorizationStatus {
        case .authorized:
            // The user has previously granted access to the camera.
            self.prepareCaptureSession()
        case .notDetermined:
            // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        // The user has granted access to the camera.
                        self?.prepareCaptureSession()
                    } else {
                        // The user has denied access to the camera.
                        // You can alert the user that camera access is necessary for certain features.
                    }
                }
            }
        case .restricted, .denied:
            // The user has previously denied access.
            // You can alert the user that camera access is necessary for certain features.
            DispatchQueue.main.async {
                print("no camera access")
            }
        @unknown default:
            fatalError("Unknown authorization status")
        }
    }

    
    func updateSaveDirectoryURL(_ url: URL) {
        self.saveDirectoryURL = url
        // Optionally, save the URL to UserDefaults here if you want it to persist across app launches
        UserDefaults.standard.set(url.path, forKey: "saveDirectoryPath")
    }
    
    func prepareCaptureSession() {
        DispatchQueue.main.async {
            self.captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  let captureSession = self.captureSession, captureSession.canAddInput(videoInput) else {
                return
            }
            
            captureSession.addInput(videoInput)
            
            if captureSession.canAddOutput(self.photoOutput) {
                captureSession.addOutput(self.photoOutput)
                captureSession.startRunning()
            }
        }
    }
    
    func startTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.captureImage()
        }
    }
    
    @objc func captureImage() {
        guard let captureSession = captureSession, captureSession.isRunning else {
            print("Capture session is not running.")
            return
        }
        
        let settings = AVCapturePhotoSettings()
        // Customize settings if needed, e.g., settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }


    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            print("Could not get image data.")
            return
        }
        
        // Assuming you want to process and send the image immediately after capture
        processAndSendImage(imageData: imageData)
    }
    
    func processAndSendImage(imageData: Data) {
        sendImageToOllamaAPI(imageBase64String: imageData.base64EncodedString())
    }
    
    func sendImageToOllamaAPI(imageBase64String: String) {
        
        guard let baseServerURLString = UserDefaults.standard.string(forKey: "serverBaseURL"),
                  let baseURL = URL(string: baseServerURLString),
                  let url = URL(string: "/api/generate", relativeTo: baseURL) else {
                print("Invalid or missing server base URL.")
                return
            }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let prompt = "Analyze the emotion displayed by the person in the provided image, focusing on key facial features such as the positioning and shape of the eyes, mouth, and the presence of any wrinkles. Interpret these features to estimate the person's emotion. For example, a smiling mouth or raised corners of the eyes may suggest 'happy', while drooping eyelids could indicate 'sleepy'. Recognize that determining emotion is subjective and based on the visible cues. Please categorize your analysis into one of the following options based on your estimation: 'happy', 'sad', 'bored', 'sleepy', or 'expressionless'. Ensure to return only one of these options as your one word response."
        let requestBody: [String: Any] = [
            "model": "llava",
            "prompt": prompt,
            "stream": false,
            "images": [imageBase64String]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responseString = jsonResponse["response"] as? String {
                    DispatchQueue.main.async {
                        self?.updateStatusBarIconBasedOnResponse(responseString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
                    }
                }
            } catch {
                print("Failed to decode response: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func updateStatusBarIconBasedOnResponse(_ response: String) {
        let systemSymbolName: String
        print(response)
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
               
        switch trimmedResponse {
        case "happy":
            systemSymbolName = "HappyIcon"
        case "sad":
            systemSymbolName = "SadIcon"
        case "sleepy":
            systemSymbolName = "SleepyIcon"
        case "no expression":
            systemSymbolName = "NoExpIcon"
        default:
            systemSymbolName = "NoExpIcon"
        }
        
        if let button = self.statusBarItem.button {
               button.image = NSImage(named: NSImage.Name(systemSymbolName))
           }
    }
}
