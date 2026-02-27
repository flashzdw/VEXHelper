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
    @StateObject private var manager = RemoteControlManager()
    @State private var isServerEnabled = false
    @State private var isRemoteAudioEnabled = true // 默认开启
    @State private var showControlMode = false
    @AppStorage("hasSeenRemoteIntro") private var hasSeenIntro = false
    @State private var showIntro = false
    
    // 使用与 TimerPage 相同的背景色
    private let darkGray = Color("darkGray")
    
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
                    // 标题栏
                    HStack {
                        Text("Remote Control")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 10)
                    .zIndex(1) // 确保标题在最上层
                    
                    ZStack(alignment: .top) {
                        Form {
                            Section(header: Text("Server Status").foregroundColor(.white.opacity(0.8))) {
                                Toggle("Enable Remote Server", isOn: $isServerEnabled)
                                    .onChange(of: isServerEnabled) { newValue in
                                        if newValue {
                                            server.start()
                                        } else {
                                            server.stop()
                                        }
                                    }
                                
                                if server.isRunning {
                                    HStack {
                                        Text("IP Address")
                                        Spacer()
                                        Text(server.serverIP)
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
                            }
                            
                            if server.isRunning {
                                Section {
                                    Button(action: {
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
                                
                                Section(header: Text("Audio Settings").foregroundColor(.white.opacity(0.8))) {
                                    Toggle("Remote Audio Only", isOn: $isRemoteAudioEnabled)
                                        .onChange(of: isRemoteAudioEnabled) { newValue in
                                            SoundsControlCenter.shared.isRemoteAudioEnabled = newValue
                                        }
                                    Text("When enabled, sound will play on the connected browser instead of this device.")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden) // 隐藏 Form 默认背景
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
                WebControlView(timerEngine: manager.remoteTimerEngine, manager: manager)
            }
            .sheet(isPresented: $showIntro) {
                introView
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            isServerEnabled = server.isRunning
            // 同步音频设置
            isRemoteAudioEnabled = SoundsControlCenter.shared.isRemoteAudioEnabled
            // 如果默认开启，确保 SoundsControlCenter 状态一致
            if isRemoteAudioEnabled {
                SoundsControlCenter.shared.isRemoteAudioEnabled = true
            }
            
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
