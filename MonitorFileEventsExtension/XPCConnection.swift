//
//  XPCConnection.swift
//  MonitorFileEventsExtension
//
//  Created by arnav on 6/22/25.
//

import Foundation

class XPCConnection {
    private var connection: NSXPCConnection?
    
    func setupConnection() {
        connection = NSXPCConnection(serviceName: "com.yourcompany.FileMonitor.XPCService")
        connection?.remoteObjectInterface = NSXPCInterface(with: FileMonitorXPCProtocol.self)
        connection?.resume()
    }
    
    func sendEvent(type: String, path: String, timestamp: Double) {
        guard let proxy = connection?.remoteObjectProxy as? FileMonitorXPCProtocol else {
            return
        }
        proxy.sendFileEvent(type: type, path: path, timestamp: timestamp)
    }
}
