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
    @State private var showControlMode = false
    @AppStorage("hasSeenRemoteIntro") private var hasSeenIntro = false
    @State private var showIntro = false

    /// Web断开连接时弹窗
    @State private var showWebDisconnectedAlert = false
    
    // 使用与 TimerPage 相同的背景色
    private let darkGray = Color("AppDarkGray")
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    init() {
        // 配置 Form 的背景为透明，以便显示底层的 darkGray
        UITableView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 统一的深色背景
                darkGray.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        Form {
                            if server.isRunning {
                                Section(header: Text("Server Status").foregroundColor(.white.opacity(0.8))) {
                                    HStack {
                                        Text("IP Address")
                                        Spacer()
                                        Text(LocalizedStringKey(server.serverIP))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack {
                                        Text("Port")
                                        Spacer()
                                        Text("8080")
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack {
                                        Text("Connected Clients")
                                        Spacer()
                                        Text("\(server.connectedClientsCount)")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Section {
                                    Button(action: {
                                        // 切换到Web计时模式
                                        sharedData.switchToWebMode()
                                        showControlMode = true
                                    }) {
                                        HStack {
                                            Spacer()
                                            Text(LocalizedStringKey("Enter Control Mode"))
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                    }
                                    .listRowBackground(Color.blue)
                                }
                                
                                // 仅当有有效 IP 时显示连接信息
                                if server.serverIP != "No Wi-Fi Connection" && server.serverIP != "Unavailable" {
                                    Section(header: Text("Connection").foregroundColor(.white.opacity(0.8))) {
                                        VStack(alignment: .center) {
                                            if let qrImage = generateQRCode(from: "http://\(server.serverIP):8080") {
                                                Image(uiImage: qrImage)
                                                    .interpolation(.none)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 200, height: 200)
                                            }
                                            
                                            Text("Scan to Connect")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            Text("http://\(server.serverIP):8080")
                                                .font(.system(.body, design: .monospaced))
                                                .textSelection(.enabled)
                                                .padding(.top, 5)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                    }
                                } else {
                                    // 无网络提示
                                    Section {
                                        HStack {
                                            Image(systemName: "wifi.slash")
                                                .foregroundColor(.red)
                                            Text("Please connect to Wi-Fi or Hotspot")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        .modifier(HideFormBackgroundModifier()) // 隐藏 Form 默认背景
                        .padding(.top, 40) // 增加顶部内边距，避开虚化遮罩
                        
                        // 顶部渐变虚化遮罩
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        darkGray,
                                        darkGray.opacity(0.8),
                                        darkGray.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 60)
                            .allowsHitTesting(false) // 允许点击穿透
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showControlMode) {
                WebControlView(timerEngine: SharedData.shared.webTimerEngine, manager: SharedData.shared.webRemoteControlManager)
            }
            .onChange(of: server.connectedClientsCount) { oldValue, newValue in
                // 当客户端数量从有变无时（Web断开），弹出提示
                if oldValue > 0 && newValue == 0 {
                    // 只有在Web计时模式下才弹出提示
                    if sharedData.activeTimerMode == .web {
                        showWebDisconnectedAlert = true
                    }
                }
            }
            .alert("Web Disconnected", isPresented: $showWebDisconnectedAlert) {
                Button("Switch to Phone Timer") {
                    sharedData.switchToPhoneMode()
                }
                Button("Stay in Web Mode", role: .cancel) {
                    // 保持在Web模式但不运行计时
                }
            } message: {
                Text("The Web client has disconnected. Would you like to switch back to phone timer mode?")
            }
            .sheet(isPresented: $showIntro) {
                introView
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if !server.isRunning {
                server.start()
            }
            // 同步音频设置 (isRemoteAudioEnabled 已经在 manager 中初始化为 true)
            
            // 首次进入显示介绍
            if !hasSeenIntro {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showIntro = true
                }
            }
        }
    }
    
    var introView: some View {
        ZStack {
            darkGray.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "network")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                Text(LocalizedStringKey("Remote Control Mode"))
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(LocalizedStringKey("Turn your device into a controller and use any browser as a large display."))
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    featureRow(icon: "tv", text: "Big screen display for competitions")
                    featureRow(icon: "speaker.wave.2", text: "Audio plays from the browser")
                    featureRow(icon: "iphone", text: "Control everything from your phone")
                }
                .padding(.vertical, 30)
                
                Spacer()
                
                Button(action: {
                    hasSeenIntro = true
                    showIntro = false
                }) {
                    Text(LocalizedStringKey("Get Started"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding()
        }
    }
    
    func featureRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(LocalizedStringKey(text))
                .foregroundColor(.white)
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
