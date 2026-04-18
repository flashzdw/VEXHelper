//
//  PhoneRemoteControlManager.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/02/01.
//

import Foundation
import Combine
import SwiftUI

/// 手机端远程控制管理器，负责协调手机端计时器引擎、网络服务和音频
/// 与 WebRemoteControlManager 完全独立，拥有自己的 isMuted 状态
class PhoneRemoteControlManager: ObservableObject {
    private let phoneTimerEngine: PhoneTimerEngine
    private let networkService: LocalNetworkService

    /// 语言监听
    private var languageCancellable: AnyCancellable?

    init(timerEngine: PhoneTimerEngine, networkService: LocalNetworkService = .shared) {
        self.phoneTimerEngine = timerEngine
        self.networkService = networkService
        setupEngine()
        setupLanguageSync()
    }

    private func setupEngine() {
        // 配置广播回调
        phoneTimerEngine.onBroadcast = { [weak self] jsonMessage in
            self?.networkService.broadcast(message: jsonMessage)
        }

        // 配置音频播放回调
        phoneTimerEngine.onPlaySound = { [weak self] soundName in
            self?.handlePlaySound(name: soundName)
        }
    }

    /// 手机端是否已静音（独立于Web端）
    @Published var isMuted: Bool = false

    /// 是否仅远程播放音频
    @Published var isRemoteAudioEnabled: Bool = true

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

        // 始终广播声音指令到 Web 端
        let json = "{\"type\": \"playSound\", \"file\": \"\(name)\"}"
        networkService.broadcast(message: json)

        // 彻底修复：只有在开启了"仅远程音频" 并且 真的有客户端连接时，才静音本地。
        // 如果没有客户端连接，必须在本地播放，否则会导致完全没声音。
        let hasConnectedClients = networkService.connectedClientsCount > 0
        let shouldPlayLocally = !(isRemoteAudioEnabled && hasConnectedClients)

        if shouldPlayLocally {
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
    }

    private var cancellables = Set<AnyCancellable>()

    /// 发送初始状态给新连接 (语言 + 时间状态)
    private func syncInitialState(to connection: WebSocketConnection) {
        // 1. Language
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        connection.send(string: "{\"type\": \"language\", \"lang\": \"\(lang)\"}")

        // 2. Mute State
        connection.send(string: "{\"type\": \"toggleMute\", \"muted\": \(isMuted)}")

        // 3. Timer State (1:00 instead of 0:00)
        // Construct current state JSON
        let statusStr: String
        switch phoneTimerEngine.status {
        case .running: statusStr = "running"
        case .paused: statusStr = "paused"
        case .stopped: statusStr = "stopped"
        case .idle: statusStr = "idle"
        }

        let json = """
        {
            "type": "update",
            "timeString": "\(phoneTimerEngine.timeString)",
            "progress": \(phoneTimerEngine.progress),
            "status": "\(statusStr)"
        }
        """
        connection.send(string: json)
    }

    /// 同步当前语言到 Web 端

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
