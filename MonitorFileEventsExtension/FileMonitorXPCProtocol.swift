//
//  FileMonitorXPCProtocol.swift
//  MonitorEvents
//
//  Created by arnav on 6/22/25.
//

import Foundation

@objc protocol FileMonitorXPCProtocol {
    func sendFileEvent(type: String, path: String, timestamp: Double)
}
