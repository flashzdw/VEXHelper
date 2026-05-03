//
//  LocalNetworkService.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/02/01.
//

import Foundation
import Network
import Combine
import UIKit

class LocalNetworkService: ObservableObject {
    static let shared = LocalNetworkService()
    
    @Published var isRunning = false
    @Published var serverIP: String = "Unknown"
    @Published var connectedClientsCount: Int = 0
    
    private var listener: NWListener?
    private var connectedWebSockets: [WebSocketConnection] = []
    private var pendingHTTPHandlers: [HTTPConnectionHandler] = []
    private let port: NWEndpoint.Port = 8080
    
    // Callback for new connections to send initial state
    var onNewConnection: ((WebSocketConnection) -> Void)?
    var onMessageReceived: ((WebSocketConnection, String) -> Void)?
    
    private init() {}
    
    func start() {
        guard !isRunning else { return }
        
        do {
            let tcpOptions = NWProtocolTCP.Options()
            tcpOptions.noDelay = true // 核心优化：禁用 Nagle 算法，关闭延迟，提高实时性
            let parameters = NWParameters(tls: nil, tcp: tcpOptions)
            parameters.allowLocalEndpointReuse = true
            let listener = try NWListener(using: parameters, on: port)
            
            listener.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.updateServerIP()
                        print("Server started on port \(self?.port.rawValue ?? 0)")
                    case .failed(let error):
                        print("Server failed with error: \(error)")
                        self?.stop()
                    default:
                        break
                    }
                }
            }
            
            listener.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener.start(queue: .global(qos: .userInitiated))
            self.listener = listener
            
        } catch {
            print("Failed to create listener: \(error)")
        }
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        
        // Close all connections
        for socket in connectedWebSockets {
            socket.stop()
        }
        connectedWebSockets.removeAll()
        
        DispatchQueue.main.async {
            self.isRunning = false
            self.connectedClientsCount = 0
        }
    }
    
    func restart() {
        stop()
        // 给系统一点时间释放端口，然后再启动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.start()
        }
    }
    
    func broadcast(message: String) {
        for socket in connectedWebSockets {
            socket.send(string: message)
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        let handler = HTTPConnectionHandler(connection: connection)
        handler.delegate = self

        // Store handler to keep it alive
        DispatchQueue.main.async {
            self.pendingHTTPHandlers.append(handler)
        }

        // 添加 30 秒超时保护，防止内存泄漏
        var timeoutWorkItem: DispatchWorkItem?
        timeoutWorkItem = DispatchWorkItem { [weak self, weak handler] in
            DispatchQueue.main.async {
                if let handler = handler {
                    self?.pendingHTTPHandlers.removeAll { $0 === handler }
                    handler.onFinish?()
                }
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 30, execute: timeoutWorkItem!)

        handler.onFinish = { [weak self, weak handler] in
            // 取消超时任务
            timeoutWorkItem?.cancel()

            DispatchQueue.main.async {
                if let handler = handler {
                    self?.pendingHTTPHandlers.removeAll { $0 === handler }
                }
            }
        }

        handler.start()
    }
    
    private func updateServerIP() {
        // Simple interface search to find local IP
        if let ip = getWiFiAddress() {
            // Check if IPv6
            if ip.contains(":") {
                self.serverIP = "[\(ip)]"
            } else {
                self.serverIP = ip
            }
        } else {
            self.serverIP = "No Wi-Fi Connection"
        }
    }
    
    // Helper to get IP
    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { return nil }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: interface.ifa_name)
                    // Check for Wi-Fi (en0) or Personal Hotspot (bridge100)
                    if name == "en0" || name == "bridge100" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        
                        let ip = String(cString: hostname)
                        // Filter out link-local IPv6 addresses (fe80::...)
                        if !ip.hasPrefix("fe80") {
                            address = ip
                            // Prefer IPv4 if found
                            if addrFamily == UInt8(AF_INET) {
                                break
                            }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}

// MARK: - HTTPConnectionDelegate
extension LocalNetworkService: HTTPConnectionDelegate {

    func didUpgradeToWebSocket(connection: WebSocketConnection) {
        print("New WebSocket connection")
        DispatchQueue.main.async {
            self.connectedWebSockets.append(connection)
            self.connectedClientsCount = self.connectedWebSockets.count
            
            connection.onMessage = { [weak self] msg in
                self?.onMessageReceived?(connection, msg)
            }
            
            // Notify listener to send initial state
            self.onNewConnection?(connection)
            
            // Clean up closed connections
            connection.onClose = { [weak self] id in
                DispatchQueue.main.async {
                    self?.connectedWebSockets.removeAll { $0.id == id }
                    self?.connectedClientsCount = self?.connectedWebSockets.count ?? 0
                }
            }
        }
    }
}
