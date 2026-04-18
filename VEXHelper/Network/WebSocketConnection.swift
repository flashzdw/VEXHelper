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

    /// 递归读取消息，使用 dispatch 避免栈溢出
    private func readMessage() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, context, isComplete, error in
            guard let self = self else { return }

            if let error = error {
                print("WS Receive error: \(error)")
                self.stop()
                return
            }

            if isComplete {
                self.stop()
                return
            }

            // 处理接收到的数据（可能包含 Ping 帧）
            if let data = content, !data.isEmpty {
                self.handleReceivedData(data)
            }

            // 使用 dispatch_async 避免递归栈过深
            DispatchQueue.global().async {
                self.readMessage()
            }
        }
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

    /// 处理接收到的数据帧
    private func handleReceivedData(_ data: Data) {
        guard data.count >= 2 else { return }

        // 解析 WebSocket 帧头
        let firstByte = data[0]
        let secondByte = data[1]

        // 检查 FIN 位和 opcode
        let opcode = firstByte & 0x0F

        // 只处理控制帧
        guard opcode == 0x08 || opcode == 0x09 || opcode == 0x0A else {
            // 非控制帧，暂时忽略（因为服务器主要发送数据给客户端）
            return
        }

        // 处理 Close 帧
        if opcode == 0x08 {
            stop()
            return
        }

        // 处理 Ping 帧
        if opcode == 0x09 {
            // 计算 payload 长度（处理 126 和 127 扩展长度）
            var payloadStartIndex = 2
            var payloadLength = Int(secondByte & 0x7F)

            if payloadLength == 126 {
                guard data.count >= 4 else {
                    sendPong(payload: Data())
                    return
                }
                payloadLength = Int(data[2]) << 8 | Int(data[3])
                payloadStartIndex = 4
            } else if payloadLength == 127 {
                guard data.count >= 10 else {
                    sendPong(payload: Data())
                    return
                }
                // 读取 8 字节长度（这里只处理低 32 位）
                payloadLength = Int(data[6]) << 24 | Int(data[7]) << 16 | Int(data[8]) << 8 | Int(data[9])
                payloadStartIndex = 10
            }

            // 提取 payload 并发送 Pong
            if data.count >= payloadStartIndex + payloadLength {
                let payload = data.subdata(in: payloadStartIndex..<(payloadStartIndex + payloadLength))
                sendPong(payload: payload)
            } else {
                sendPong(payload: Data())
            }
            return
        }

        // 处理 Pong 帧（主动发送的 pong 不需要响应）
        if opcode == 0x0A {
            return
        }
    }

    /// 发送 Pong 响应
    private func sendPong(payload: Data) {
        var frame = Data()

        // Byte 0: FIN(1) | RSV1-3(0) | Opcode(0x0A for pong)
        frame.append(0x8A)

        // Byte 1: Mask(0) | Payload Len
        let length = payload.count
        if length < 126 {
            frame.append(UInt8(length))
        } else if length <= 65535 {
            frame.append(126)
            frame.append(UInt8((length >> 8) & 0xFF))
            frame.append(UInt8(length & 0xFF))
        } else {
            frame.append(127)
            for i in stride(from: 56, through: 0, by: -8) {
                frame.append(UInt8((length >> i) & 0xFF))
            }
        }

        frame.append(payload)

        connection.send(content: frame, completion: .contentProcessed({ error in
            if let error = error {
                print("WS Pong send error: \(error)")
            }
        }))
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
