//
//  WebSocketConnection.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/02/01.
//

import Foundation
import Network

class WebSocketConnection: Identifiable {
    let id = UUID()
    private let connection: NWConnection
    var onClose: ((UUID) -> Void)?
    
    init(connection: NWConnection) {
        self.connection = connection
        start()
    }
    
    private func start() {
        // Start reading messages
        readMessage()
    }
    
    func stop() {
        connection.cancel()
        onClose?(id)
    }
    
    func send(string: String) {
        guard let data = string.data(using: .utf8) else { return }
        let frame = createFrame(data: data)
        connection.send(content: frame, completion: .contentProcessed({ error in
            if let error = error {
                print("WS Send error: \(error)")
                self.stop()
            }
        }))
    }
    
    private func readMessage() {
        // In a full implementation, we need to parse the WS frame header.
        // For this simple implementation (Server -> Client mainly), we might not strictly parse incoming control frames yet,
        // but we should at least listen for closure or keep-alive.
        // For now, we just keep the connection open.
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, context, isComplete, error in
            if let error = error {
                print("WS Receive error: \(error)")
                self?.stop()
                return
            }
            
            if isComplete {
                self?.stop()
                return
            }
            
            // If we receive data, we should parse it. 
            // Since our Client (Browser) is Read-Only, we might ignore incoming data for now 
            // or implement basic ping/pong if needed.
            
            // Continue reading
            self?.readMessage()
        }
    }
    
    // Create a simple unmasked text frame (Server -> Client)
    private func createFrame(data: Data) -> Data {
        var frame = Data()
        
        // Byte 0: FIN(1) | RSV1-3(0) | Opcode(1 for text)
        frame.append(0x81)
        
        // Byte 1: Mask(0) | Payload Len
        let length = data.count
        if length < 126 {
            frame.append(UInt8(length))
        } else if length <= 65535 {
            frame.append(126)
            frame.append(UInt8((length >> 8) & 0xFF))
            frame.append(UInt8(length & 0xFF))
        } else {
            frame.append(127)
            // 64-bit length (only using lower 64 bits essentially, but Swift Int is 64 bit)
            for i in stride(from: 56, through: 0, by: -8) {
                frame.append(UInt8((length >> i) & 0xFF))
            }
        }
        
        frame.append(data)
        return frame
    }
}
