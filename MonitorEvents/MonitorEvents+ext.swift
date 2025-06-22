//
//  MonitorEvents+ext.swift
//  MonitorEvents
//
//  Created by arnav on 6/22/25.
//

import Foundation
import EndpointSecurity
import SystemExtensions

extension ViewController: OSSystemExtensionRequestDelegate {
    
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension extension: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
//        statusLabel.stringValue = "Extension needs user approval in System Preferences"
        logEvent("User approval required - check System Preferences > Security & Privacy")
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        switch result {
        case .completed:
          //  statusLabel.stringValue = "Extension installed successfully"
            logEvent("System extension activated successfully")
         //   installButton.isEnabled = false
         //   uninstallButton.isEnabled = true
            
        case .willCompleteAfterReboot:
//            statusLabel.stringValue = "Extension will activate after reboot"
            logEvent("System extension will activate after reboot")
            
        @unknown default:
//            statusLabel.stringValue = "Unknown installation result"
            logEvent("Unknown installation result")
        }
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
//        statusLabel.stringValue = "Extension installation failed"
        logEvent("Installation failed: \(error.localizedDescription)")
    }
}
