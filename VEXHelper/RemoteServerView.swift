//
//  RemoteServerView.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/02/01.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct RemoteServerView: View {
    @ObservedObject private var server = LocalNetworkService.shared
    @ObservedObject private var sharedData = SharedData.shared

    @State private var showWebDisconnectedToast = false
    @State private var showRestartToast = false
    
    // 使用与 TimerPage 相同的背景色
    private let darkGray = Color("AppDarkGray")
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var connectionStatus: ConnectionStatus {
        if !server.isRunning || server.serverIP == "No Wi-Fi Connection" || server.serverIP == "Unavailable" {
            return .disconnected
        } else if server.connectedClientsCount > 0 {
            return .connected
        } else {
            return .waiting
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // 统一的深色背景
                darkGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 标题区域
                        HStack {
                            Text("Connection")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.white)
                            Spacer()
                            
                            Button(action: {
                                // 触发服务器重启
                                server.restart()
                                
                                // 显示重启 Toast
                                withAnimation(.spring()) {
                                    showRestartToast = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(.spring()) {
                                        showRestartToast = false
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                        
                        if server.isRunning {
                            // 服务器状态卡片
                            GlassCardView {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("Server Status")
                                            .font(.headline)
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                        StatusDotView(status: connectionStatus)
                                    }
                                    
                                    Divider().background(Color.white.opacity(0.2))
                                    
                                    HStack {
                                        Text("IP Address")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(LocalizedStringKey(server.serverIP))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack {
                                        Text("Port")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("8080")
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack {
                                        Text("Connected Clients")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(server.connectedClientsCount)")
                                            .foregroundColor(server.connectedClientsCount > 0 ? .green : .gray)
                                            .fontWeight(server.connectedClientsCount > 0 ? .bold : .regular)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // 二维码区域
                            if connectionStatus != .disconnected {
                                GlassCardView {
                                    VStack(alignment: .center, spacing: 16) {
                                        Text("Scan to Connect")
                                            .font(.headline)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        if let qrImage = generateQRCode(from: "http://\(server.serverIP):8080") {
                                            Image(uiImage: qrImage)
                                                .interpolation(.none)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 220, height: 220)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                                .shadow(radius: 10)
                                        }
                                        
                                        Text("http://\(server.serverIP):8080")
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(8)
                                            .textSelection(.enabled)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 24)
                            } else {
                                // 无网络提示卡片
                                GlassCardView {
                                    HStack(spacing: 16) {
                                        Image(systemName: "wifi.slash")
                                            .font(.system(size: 24))
                                            .foregroundColor(.red)
                                        Text("Please connect to Wi-Fi or Hotspot")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // 顶部 Toast 提示
                VStack {
                    if showWebDisconnectedToast {
                        ToastBannerView(message: "Web client disconnected.", systemImage: "exclamationmark.triangle.fill", isError: true)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 10)
                    }
                    
                    if showRestartToast {
                        ToastBannerView(message: "Server restarted.", systemImage: "checkmark.circle.fill", isError: false)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 10)
                    }
                }
                .zIndex(2)
            }
            .navigationBarHidden(true)
            .onChange(of: server.connectedClientsCount) { oldValue, newValue in
                // 当客户端数量从有变无时（Web断开），弹出Toast提示
                if oldValue > 0 && newValue == 0 {
                    if sharedData.activeTimerMode == .web {
                        withAnimation(.spring()) {
                            showWebDisconnectedToast = true
                        }
                        // 3秒后自动隐藏
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.spring()) {
                                showWebDisconnectedToast = false
                            }
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if !server.isRunning {
                server.start()
            }
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return nil
    }
}
