//
//  ESClient.swift
//  MonitorFileEventsExtension
//
//  Created by arnav on 6/22/25.
//

import Foundation
import EndpointSecurity
import SystemExtensions

class EndpointSecurityExtension: NSObject, NSExtensionRequestHandling {
    
    var client: OpaquePointer?
    
    func beginRequest(with context: NSExtensionContext) {
        // Initialize the endpoint security client
        initializeEndpointSecurity()
    }
    
    private func initializeEndpointSecurity() {
        // Create the ES client
        let result = es_new_client(&client) { client, message in
            // Handle endpoint security messages
            self.handleEndpointSecurityMessage(client: client, message: message)
        }
        
        guard result == ES_NEW_CLIENT_RESULT_SUCCESS else {
            print("Failed to create ES client: \(result)")
            return
        }
        
        // Subscribe to file events
        subscribeToEvents()
    }
    
    private func subscribeToEvents() {
        let events: [es_event_type_t] = [
            ES_EVENT_TYPE_NOTIFY_CREATE,
            ES_EVENT_TYPE_NOTIFY_WRITE,
            ES_EVENT_TYPE_NOTIFY_UNLINK,
            ES_EVENT_TYPE_NOTIFY_RENAME,
            ES_EVENT_TYPE_NOTIFY_CLOSE
        ]
        
        guard let esClient = client else { return}
        let result = es_subscribe(esClient, events, UInt32(events.count))
        if result != ES_RETURN_SUCCESS {
            print("Failed to subscribe to events: \(result)")
        }
    }
    
    private func handleEndpointSecurityMessage(client: OpaquePointer?, message: UnsafePointer<es_message_t>) {
        let msg = message.pointee
        
        switch msg.event_type {
        case ES_EVENT_TYPE_NOTIFY_CREATE:
            handleFileCreate(message: msg)
        case ES_EVENT_TYPE_NOTIFY_WRITE:
            handleFileWrite(message: msg)
        case ES_EVENT_TYPE_NOTIFY_UNLINK:
            handleFileDelete(message: msg)
        case ES_EVENT_TYPE_NOTIFY_RENAME:
            handleFileRename(message: msg)
        case ES_EVENT_TYPE_NOTIFY_CLOSE:
            handleFileClose(message: msg)
        default:
            break
        }
    }
    
    private func handleFileCreate(message: es_message_t) {
        let event = message.event.create
        if let path = getPath(from: event.destination.dir, filename: event.destination.filename) {
            sendEventToHost(type: "CREATE", path: path)
        }
    }
    
    private func handleFileWrite(message: es_message_t) {
        let event = message.event.write
        if let path = getPath(from: event.target) {
            sendEventToHost(type: "WRITE", path: path)
        }
    }
    
    private func handleFileDelete(message: es_message_t) {
        let event = message.event.unlink
        if let path = getPath(from: event.target) {
            sendEventToHost(type: "DELETE", path: path)
        }
    }
    
    private func handleFileRename(message: es_message_t) {
        let event = message.event.rename
        if let sourcePath = getPath(from: event.source),
           let destPath = getPath(from: event.destination.dir, filename: event.destination.filename) {
            sendEventToHost(type: "RENAME", path: "\(sourcePath) -> \(destPath)")
        }
    }
    
    private func handleFileClose(message: es_message_t) {
        let event = message.event.close
        if let path = getPath(from: event.target) {
            sendEventToHost(type: "CLOSE", path: path)
        }
    }
    
    private func getPath(from file: es_file_t) -> String? {
        return String(cString: file.path.data, encoding: .utf8)
    }
    
    private func getPath(from dir: es_file_t, filename: es_string_token_t) -> String? {
        guard let dirPath = String(cString: dir.path.data, encoding: .utf8),
              let fileName = String(cString: filename.data, encoding: .utf8) else {
            return nil
        }
        return "\(dirPath)/\(fileName)"
    }
    
    private func sendEventToHost(type: String, path: String) {
        // Send event to host app via XPC or other IPC mechanism
        let eventData: [String: Any] = [
            "type": type,
            "path": path,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // For now, just log the event
        print("File Event: \(type) - \(path)")
        
        // TODO: Implement XPC communication to host app
    }
    
    deinit {
        if let client = client {
            es_delete_client(client)
        }
    }
}
