//
//  RemoteControlManager.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/02/01.
//

import Foundation
import Combine
import SwiftUI

/// 远程控制管理器，负责协调远程计时器引擎、网络服务和音频
class RemoteControlManager: ObservableObject {
    /// 远程专用计时器引擎
    @Published var remoteTimerEngine: TimerEngine
    
    /// 网络服务引用
    private let networkService = LocalNetworkService.shared
    
    /// 语言监听
    private var languageCancellable: AnyCancellable?
    
    init() {
        self.remoteTimerEngine = TimerEngine()
        setupEngine()
        setupLanguageSync()
    }
    
    private func setupEngine() {
        // 配置广播回调
        remoteTimerEngine.onBroadcast = { [weak self] jsonMessage in
            self?.networkService.broadcast(message: jsonMessage)
        }
        
        // 配置音频播放回调
        remoteTimerEngine.onPlaySound = { [weak self] soundName in
            self?.handlePlaySound(name: soundName)
        }
    }
    
    /// 是否已全局静音
    @Published var isMuted: Bool = false
    
    /// 切换静音状态
    func toggleMute() {
        isMuted.toggle()
        
        // 发送静音指令到 Web 端
        let json = "{\"type\": \"toggleMute\", \"muted\": \(isMuted)}"
        networkService.broadcast(message: json)
        
        // 如果正在本地播放，也应该停止
        if isMuted {
            // SoundsControlCenter.shared.stop() // 如果有停止方法
        }
    }
    
    private func handlePlaySound(name: String) {
        // 如果已静音，直接返回，不播放任何声音
        if isMuted { return }
        
        // 1. 如果开启了远程音频，发送指令到 Web 端
        if SoundsControlCenter.shared.isRemoteAudioEnabled {
            let json = "{\"type\": \"playSound\", \"file\": \"\(name)\"}"
            networkService.broadcast(message: json)
        } else {
            // 2. 否则本地播放
            DispatchQueue.main.async {
                SoundsControlCenter.shared.updateSoundPlayer(with: name)
            }
        }
    }
    
    private func setupLanguageSync() {
        // 监听 UserDefaults 中的语言设置变化
        languageCancellable = UserDefaults.standard.publisher(for: \.appLanguage)
            .sink { [weak self] _ in
                self?.syncLanguage()
            }
        
        // 监听新的连接，一旦有新连接，立即同步语言
        networkService.$connectedClientsCount
            .sink { [weak self] count in
                if count > 0 {
                    // 延迟一点点确保连接完全建立
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.syncLanguage()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// 同步当前语言到 Web 端
    func syncLanguage() {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let json = "{\"type\": \"language\", \"lang\": \"\(lang)\"}"
        networkService.broadcast(message: json)
        
        // 同时同步静音状态
        let muteJson = "{\"type\": \"toggleMute\", \"muted\": \(isMuted)}"
        networkService.broadcast(message: muteJson)
    }
}

// 扩展 UserDefaults 以支持 publisher
extension UserDefaults {
    @objc dynamic var appLanguage: String? {
        return string(forKey: "appLanguage")
    }
}
