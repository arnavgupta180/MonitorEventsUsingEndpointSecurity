//
//  ViewController.swift
//  MonitorEvents
//
//  Created by arnav on 6/21/25.
//

import Cocoa
import SystemExtensions
import EndpointSecurity

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let request = OSSystemExtensionRequest.activationRequest(
                 forExtensionWithIdentifier: "com.yourcompany.FileMonitor.FileMonitorExtension",
                 queue: .main
             )
             request.delegate = self
             OSSystemExtensionManager.shared.submitRequest(request)
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    private func shouldMonitorPath(_ path: String) -> Bool {
        let excludedPaths = ["/System/", "/Library/Caches/", "/private/tmp/"]
        return !excludedPaths.contains { path.hasPrefix($0) }
    }
    
    private func checkExtensionStatus() {
        // Implementation to check if extension is running
        // This would typically involve XPC communication
    }
    
     func logEvent(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let logMessage = "[\(timestamp)] \(message)\n"
            print(logMessage)
//            let textStorage = self.eventsTextView.textStorage!
//            textStorage.append(NSAttributedString(string: logMessage))
            
            // Auto-scroll to bottom
//            let range = NSRange(location: textStorage.length, length: 0)
//            self.eventsTextView.scrollRangeToVisible(range)
        }
    }

}

