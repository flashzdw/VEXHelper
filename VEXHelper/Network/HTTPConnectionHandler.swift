//
//  HTTPConnectionHandler.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/02/01.
//

import Foundation
import Network
import CryptoKit

protocol HTTPConnectionDelegate: AnyObject {
    func didUpgradeToWebSocket(connection: WebSocketConnection)
}

class HTTPConnectionHandler {
    let connection: NWConnection
    weak var delegate: HTTPConnectionDelegate?
    var onFinish: (() -> Void)?
    
    init(connection: NWConnection) {
        self.connection = connection
    }
    
    func start() {
        connection.start(queue: .global(qos: .userInitiated))
        readRequest()
    }
    
    private func readRequest() {
        // Read headers (simplified, assuming < 64KB)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, context, isComplete, error in
            guard let self = self, let data = content, error == nil else {
                self?.connection.cancel()
                self?.onFinish?()
                return
            }
            
            guard let requestString = String(data: data, encoding: .utf8), !requestString.isEmpty else {
                 self.onFinish?()
                 return
            }
            
            if self.isWebSocketUpgrade(requestString) {
                self.handleWebSocketUpgrade(request: requestString)
            } else {
                self.handleHTTPRequest(request: requestString)
            }
        }
    }
    
    private func isWebSocketUpgrade(_ request: String) -> Bool {
        return request.contains("Upgrade: websocket") && request.contains("Sec-WebSocket-Key")
    }
    
    private func handleWebSocketUpgrade(request: String) {
        // Extract Key
        guard let keyRange = request.range(of: "Sec-WebSocket-Key: ") else { return }
        let rest = request[keyRange.upperBound...]
        let key = rest.components(separatedBy: "\r\n").first?.trimmingCharacters(in: .whitespaces) ?? ""
        
        let acceptKey = computeAcceptKey(key: key)
        
        let response = "HTTP/1.1 101 Switching Protocols\r\n" +
                       "Upgrade: websocket\r\n" +
                       "Connection: Upgrade\r\n" +
                       "Sec-WebSocket-Accept: \(acceptKey)\r\n\r\n"
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ [weak self] error in
            guard let self = self, error == nil else {
                self?.onFinish?()
                return 
            }
            let wsConnection = WebSocketConnection(connection: self.connection)
            self.delegate?.didUpgradeToWebSocket(connection: wsConnection)
            self.onFinish?()
        }))
    }
    
    private func handleHTTPRequest(request: String) {
        // Parse Method and Path
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        let parts = requestLine.components(separatedBy: " ")
        if parts.count < 2 { return }
        
        let method = parts[0]
        let path = parts[1]
        
        if method == "GET" {
            serveFile(path: path)
        } else {
            sendResponse(status: "405 Method Not Allowed", body: "Only GET supported")
        }
    }
    
    private func serveFile(path: String) {
        // Router
        var resourceName = ""
        var resourceExt = ""
        var mimeType = "text/html"
        
        if path == "/" || path == "/index.html" {
            resourceName = "index"
            resourceExt = "html"
        } else if path == "/style.css" {
            resourceName = "style"
            resourceExt = "css"
            mimeType = "text/css"
        } else if path == "/app.js" {
            resourceName = "app"
            resourceExt = "js"
            mimeType = "application/javascript"
        } else if path.hasPrefix("/audio/") {
            // /audio/Start.MP3
            let filename = path.replacingOccurrences(of: "/audio/", with: "")

            // 安全验证：防止路径遍历攻击
            let dangerousPatterns = ["..", "/", "\\", "\0", "%"]
            let isDangerous = dangerousPatterns.contains { filename.contains($0) }
            if isDangerous {
                sendResponse(status: "400 Bad Request", body: "Invalid filename")
                return
            }

            let components = filename.components(separatedBy: ".")
            if components.count == 2 {
                resourceName = components[0]
                resourceExt = components[1]
                mimeType = "audio/mpeg"
            }
        }
        
        if let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt) {
            do {
                let data = try Data(contentsOf: url)
                let header = "HTTP/1.1 200 OK\r\n" +
                             "Content-Type: \(mimeType)\r\n" +
                             "Content-Length: \(data.count)\r\n" +
                             "Connection: close\r\n\r\n"
                
                connection.send(content: header.data(using: .utf8), completion: .idempotent)
                connection.send(content: data, completion: .contentProcessed({ [weak self] _ in
                    self?.connection.cancel()
                    self?.onFinish?()
                }))
            } catch {
                sendResponse(status: "500 Internal Server Error", body: "Failed to read file")
            }
        } else {
            // Try to find in subdirectories if not found at root
            // Specifically for audio which might be in "Audio" folder
            if let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt, subdirectory: "Audio") {
                 do {
                     let data = try Data(contentsOf: url)
                     let header = "HTTP/1.1 200 OK\r\n" +
                                  "Content-Type: \(mimeType)\r\n" +
                                  "Content-Length: \(data.count)\r\n" +
                                  "Connection: close\r\n\r\n"
                     
                     connection.send(content: header.data(using: .utf8), completion: .idempotent)
                     connection.send(content: data, completion: .contentProcessed({ [weak self] _ in
                         self?.connection.cancel()
                         self?.onFinish?()
                     }))
                 } catch {
                     sendResponse(status: "500 Internal Server Error", body: "Failed to read file")
                 }
            } else {
                sendResponse(status: "404 Not Found", body: "File not found: \(path)")
            }
        }
    }
    
    private func sendResponse(status: String, body: String) {
        let response = "HTTP/1.1 \(status)\r\n" +
                       "Content-Length: \(body.count)\r\n" +
                       "Connection: close\r\n\r\n" +
                       body
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ [weak self] _ in
            self?.connection.cancel()
            self?.onFinish?()
        }))
    }
    
    private func computeAcceptKey(key: String) -> String {
        let magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        let combined = key + magic
        let data = combined.data(using: .utf8)!

        // 使用 CryptoKit 的 Insecure.SHA1 替代 CommonCrypto
        let digest = Insecure.SHA1.hash(data: data)

        return Data(digest).base64EncodedString()
    }
}
