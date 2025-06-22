//
//  main.swift
//  MonitorFileEventsExtension
//
//  Created by arnav on 6/21/25.
//

import Foundation
import EndpointSecurity

var client: OpaquePointer?

// Create the client
let res = es_new_client(&client) { (client, message) in
    // Do processing on the message received
}

if res != ES_NEW_CLIENT_RESULT_SUCCESS {
    exit(EXIT_FAILURE)
}

dispatchMain()


//# macOS Endpoint Security Framework: Step-by-Step Guide
//
//## Overview
//
//This guide walks you through creating an endpoint security framework and host application that monitors file events on macOS using Apple's Endpoint Security (ES) framework.
//
//## Prerequisites
//
//- macOS 10.15+ (Catalina or later)
//- Xcode 11+ with Command Line Tools
//- Apple Developer Account (for code signing and entitlements)
//- Administrator privileges
//- Basic knowledge of C/Objective-C and Swift
//
//## Architecture Overview
//
//The solution consists of two main components:
//1. **System Extension** - Runs with elevated privileges to monitor file events
//2. **Host Application** - User-facing app that manages the extension and displays events
//
//## Step 1: Project Setup
//
//### 1.1 Create Main Application Project
//
//1. Open Xcode and create a new macOS App project
//2. Choose Swift as the language
//3. Name it something like "FileMonitor"
//4. Ensure "Use Core Data" is unchecked for simplicity
//
//### 1.2 Add System Extension Target
//
//1. In Xcode, go to File → New → Target
//2. Choose "System Extension" under macOS
//3. Name it "FileMonitorExtension"
//4. Choose Objective-C or Swift (this guide uses Swift)
//
//## Step 2: Configure Entitlements and Info.plist
//
//### 2.1 Main App Entitlements
//
//Create `FileMonitor.entitlements`:
//
//```xml
//<?xml version="1.0" encoding="UTF-8"?>
//<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
//<plist version="1.0">
//<dict>
//    <key>com.apple.application-identifier</key>
//    <string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
//    <key>com.apple.developer.system-extension.install</key>
//    <true/>
//</dict>
//</plist>
//```
//
//### 2.2 System Extension Entitlements
//
//Create `FileMonitorExtension.entitlements`:
//
//```xml
//<?xml version="1.0" encoding="UTF-8"?>
//<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
//<plist version="1.0">
//<dict>
//    <key>com.apple.application-identifier</key>
//    <string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
//    <key>com.apple.developer.endpoint-security.client</key>
//    <true/>
//</dict>
//</plist>
//```
//
//### 2.3 Update Extension Info.plist
//
//Add to the extension's `Info.plist`:
//
//```xml
//<key>NSSystemExtensionUsageDescription</key>
//<string>This system extension monitors file system events for security purposes.</string>
//<key>NSExtension</key>
//<dict>
//    <key>NSExtensionPointIdentifier</key>
//    <string>com.apple.endpoint-security</string>
//    <key>NSExtensionPrincipalClass</key>
//    <string>$(PRODUCT_MODULE_NAME).EndpointSecurityExtension</string>
//</dict>
//```
//
//## Step 3: Implement the System Extension
//
//### 3.1 Create Extension Principal Class
//
//Create `EndpointSecurityExtension.swift` in the extension target:
//
//```swift
//import Foundation
//import EndpointSecurity
//import SystemExtensions
//
//class EndpointSecurityExtension: NSObject, NSExtensionRequestHandling {
//    
//    var client: OpaquePointer?
//    
//    func beginRequest(with context: NSExtensionContext) {
//        // Initialize the endpoint security client
//        initializeEndpointSecurity()
//    }
//    
//    private func initializeEndpointSecurity() {
//        // Create the ES client
//        let result = es_new_client(&client) { client, message in
//            // Handle endpoint security messages
//            self.handleEndpointSecurityMessage(client: client, message: message)
//        }
//        
//        guard result == ES_NEW_CLIENT_RESULT_SUCCESS else {
//            print("Failed to create ES client: \(result)")
//            return
//        }
//        
//        // Subscribe to file events
//        subscribeToEvents()
//    }
//    
//    private func subscribeToEvents() {
//        let events: [es_event_type_t] = [
//            ES_EVENT_TYPE_NOTIFY_CREATE,
//            ES_EVENT_TYPE_NOTIFY_WRITE,
//            ES_EVENT_TYPE_NOTIFY_UNLINK,
//            ES_EVENT_TYPE_NOTIFY_RENAME,
//            ES_EVENT_TYPE_NOTIFY_CLOSE
//        ]
//        
//        let result = es_subscribe(client, events, UInt32(events.count))
//        if result != ES_RETURN_SUCCESS {
//            print("Failed to subscribe to events: \(result)")
//        }
//    }
//    
//    private func handleEndpointSecurityMessage(client: OpaquePointer?, message: UnsafePointer<es_message_t>) {
//        let msg = message.pointee
//        
//        switch msg.event_type {
//        case ES_EVENT_TYPE_NOTIFY_CREATE:
//            handleFileCreate(message: msg)
//        case ES_EVENT_TYPE_NOTIFY_WRITE:
//            handleFileWrite(message: msg)
//        case ES_EVENT_TYPE_NOTIFY_UNLINK:
//            handleFileDelete(message: msg)
//        case ES_EVENT_TYPE_NOTIFY_RENAME:
//            handleFileRename(message: msg)
//        case ES_EVENT_TYPE_NOTIFY_CLOSE:
//            handleFileClose(message: msg)
//        default:
//            break
//        }
//    }
//    
//    private func handleFileCreate(message: es_message_t) {
//        let event = message.event.create
//        if let path = getPath(from: event.destination.dir, filename: event.destination.filename) {
//            sendEventToHost(type: "CREATE", path: path)
//        }
//    }
//    
//    private func handleFileWrite(message: es_message_t) {
//        let event = message.event.write
//        if let path = getPath(from: event.target) {
//            sendEventToHost(type: "WRITE", path: path)
//        }
//    }
//    
//    private func handleFileDelete(message: es_message_t) {
//        let event = message.event.unlink
//        if let path = getPath(from: event.target) {
//            sendEventToHost(type: "DELETE", path: path)
//        }
//    }
//    
//    private func handleFileRename(message: es_message_t) {
//        let event = message.event.rename
//        if let sourcePath = getPath(from: event.source),
//           let destPath = getPath(from: event.destination.dir, filename: event.destination.filename) {
//            sendEventToHost(type: "RENAME", path: "\(sourcePath) -> \(destPath)")
//        }
//    }
//    
//    private func handleFileClose(message: es_message_t) {
//        let event = message.event.close
//        if let path = getPath(from: event.target) {
//            sendEventToHost(type: "CLOSE", path: path)
//        }
//    }
//    
//    private func getPath(from file: es_file_t) -> String? {
//        return String(cString: file.path.data, encoding: .utf8)
//    }
//    
//    private func getPath(from dir: es_file_t, filename: es_string_token_t) -> String? {
//        guard let dirPath = String(cString: dir.path.data, encoding: .utf8),
//              let fileName = String(cString: filename.data, encoding: .utf8) else {
//            return nil
//        }
//        return "\(dirPath)/\(fileName)"
//    }
//    
//    private func sendEventToHost(type: String, path: String) {
//        // Send event to host app via XPC or other IPC mechanism
//        let eventData: [String: Any] = [
//            "type": type,
//            "path": path,
//            "timestamp": Date().timeIntervalSince1970
//        ]
//        
//        // For now, just log the event
//        print("File Event: \(type) - \(path)")
//        
//        // TODO: Implement XPC communication to host app
//    }
//    
//    deinit {
//        if let client = client {
//            es_delete_client(client)
//        }
//    }
//}
//```
//
//## Step 4: Implement the Host Application
//
//### 4.1 Create Main View Controller
//
//Create `ViewController.swift` for the main app:
//
//```swift
//import Cocoa
//import SystemExtensions
//
//class ViewController: NSViewController {
//    
//    @IBOutlet weak var statusLabel: NSTextField!
//    @IBOutlet weak var eventsTextView: NSTextView!
//    @IBOutlet weak var installButton: NSButton!
//    @IBOutlet weak var uninstallButton: NSButton!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        checkExtensionStatus()
//    }
//    
//    private func setupUI() {
//        statusLabel.stringValue = "Extension status: Unknown"
//        eventsTextView.isEditable = false
//        eventsTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
//    }
//    
//    @IBAction func installExtension(_ sender: NSButton) {
//        let request = OSSystemExtensionRequest.activationRequest(
//            forExtensionWithIdentifier: "com.yourcompany.FileMonitor.FileMonitorExtension",
//            queue: .main
//        )
//        request.delegate = self
//        OSSystemExtensionManager.shared.submitRequest(request)
//    }
//    
//    @IBAction func uninstallExtension(_ sender: NSButton) {
//        let request = OSSystemExtensionRequest.deactivationRequest(
//            forExtensionWithIdentifier: "com.yourcompany.FileMonitor.FileMonitorExtension",
//            queue: .main
//        )
//        request.delegate = self
//        OSSystemExtensionManager.shared.submitRequest(request)
//    }
//    
//    private func checkExtensionStatus() {
//        // Implementation to check if extension is running
//        // This would typically involve XPC communication
//    }
//    
//    private func logEvent(_ message: String) {
//        DispatchQueue.main.async {
//            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
//            let logMessage = "[\(timestamp)] \(message)\n"
//            
//            let textStorage = self.eventsTextView.textStorage!
//            textStorage.append(NSAttributedString(string: logMessage))
//            
//            // Auto-scroll to bottom
//            let range = NSRange(location: textStorage.length, length: 0)
//            self.eventsTextView.scrollRangeToVisible(range)
//        }
//    }
//}
//
//// MARK: - OSSystemExtensionRequestDelegate
//extension ViewController: OSSystemExtensionRequestDelegate {
//    
//    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension extension: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
//        return .replace
//    }
//    
//    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
//        statusLabel.stringValue = "Extension needs user approval in System Preferences"
//        logEvent("User approval required - check System Preferences > Security & Privacy")
//    }
//    
//    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
//        switch result {
//        case .completed:
//            statusLabel.stringValue = "Extension installed successfully"
//            logEvent("System extension activated successfully")
//            installButton.isEnabled = false
//            uninstallButton.isEnabled = true
//            
//        case .willCompleteAfterReboot:
//            statusLabel.stringValue = "Extension will activate after reboot"
//            logEvent("System extension will activate after reboot")
//            
//        @unknown default:
//            statusLabel.stringValue = "Unknown installation result"
//            logEvent("Unknown installation result")
//        }
//    }
//    
//    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
//        statusLabel.stringValue = "Extension installation failed"
//        logEvent("Installation failed: \(error.localizedDescription)")
//    }
//}
//```
//
//## Step 5: Inter-Process Communication (XPC)
//
//### 5.1 Create XPC Service Protocol
//
//Create `FileMonitorXPCProtocol.swift`:
//
//```swift
//import Foundation
//
//@objc protocol FileMonitorXPCProtocol {
//    func sendFileEvent(type: String, path: String, timestamp: Double)
//}
//```
//
//### 5.2 Implement XPC in Extension
//
//Add to your extension class:
//
//```swift
//import Network
//
//class XPCConnection {
//    private var connection: NSXPCConnection?
//    
//    func setupConnection() {
//        connection = NSXPCConnection(serviceName: "com.yourcompany.FileMonitor.XPCService")
//        connection?.remoteObjectInterface = NSXPCInterface(with: FileMonitorXPCProtocol.self)
//        connection?.resume()
//    }
//    
//    func sendEvent(type: String, path: String, timestamp: Double) {
//        guard let proxy = connection?.remoteObjectProxy as? FileMonitorXPCProtocol else {
//            return
//        }
//        proxy.sendFileEvent(type: type, path: path, timestamp: timestamp)
//    }
//}
//```
//
//## Step 6: Build Configuration
//
//### 6.1 Update Build Settings
//
//1. Set deployment target to macOS 10.15+
//2. Enable "Hardened Runtime" for both targets
//3. Configure code signing with your developer certificate
//4. Ensure the extension bundle ID follows the pattern: `mainapp.bundleid.extensionname`
//
//### 6.2 Embedding Extension in Main App
//
//1. In the main app target's Build Phases
//2. Add "Copy Files" phase
//3. Set destination to "Contents/Library/SystemExtensions"
//4. Add the extension target
//
//## Step 7: Testing and Deployment
//
//### 7.1 Testing Steps
//
//1. Build and run the main application
//2. Click "Install Extension"
//3. Approve the system extension in System Preferences
//4. Test file operations to see events
//
//### 7.2 Important Notes
//
//- System extensions require user approval on first install
//- The extension runs independently of the main app
//- Full Disk Access may be required for comprehensive monitoring
//- Extensions are cached by the system and may require system reboot for updates during development
//
//### 7.3 Distribution Requirements
//
//- Apps using endpoint security must be distributed through Mac App Store or with Developer ID signing
//- Users must explicitly approve endpoint security extensions
//- Consider implementing proper logging and crash reporting
//
//## Step 8: Enhanced Features
//
//### 8.1 Event Filtering
//
//Implement filtering to reduce noise:
//
//```swift
//private func shouldMonitorPath(_ path: String) -> Bool {
//    let excludedPaths = ["/System/", "/Library/Caches/", "/private/tmp/"]
//    return !excludedPaths.contains { path.hasPrefix($0) }
//}
//```
//
//### 8.2 Event Persistence
//
//Consider storing events in a database or structured log files for later analysis.
//
//### 8.3 Real-time Dashboard
//
//Enhance the UI with real-time event visualization, statistics, and filtering capabilities.
//
//## Troubleshooting
//
//### Common Issues
//
//1. **ES_NEW_CLIENT_RESULT_ERR_NOT_ENTITLED**: Check entitlements configuration
//2. **Extension won't install**: Verify bundle IDs and code signing
//3. **No events received**: Check if Full Disk Access is granted
//4. **Extension crashes**: Check system logs in Console.app
//
//### Debugging Tips
//
//- Use Console.app to view system extension logs
//- Enable endpoint security logging: `sudo log config --subsystem com.apple.endpointsecurity --category client --mode level:debug`
//- Test with simple file operations first
//
//## Security Considerations
//
//- Always validate and sanitize file paths
//- Implement proper error handling
//- Use minimal required permissions
//- Consider rate limiting for high-frequency events
//- Implement secure communication between extension and host app
//
//This framework provides a solid foundation for building endpoint security solutions on macOS while following Apple's security guidelines and best practices.
