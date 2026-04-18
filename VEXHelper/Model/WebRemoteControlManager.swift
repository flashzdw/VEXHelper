//
//  WebRemoteControlManager.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/02/01.
//

import Foundation
import Combine
import SwiftUI

/// Web端远程控制管理器，负责协调Web端计时器引擎、网络服务和音频
/// 与 PhoneRemoteControlManager 完全独立，拥有自己的 isMuted 状态
class WebRemoteControlManager: ObservableObject {
    private let webTimerEngine: WebTimerEngine
    private let networkService: LocalNetworkService

    /// 语言监听
    private var languageCancellable: AnyCancellable?

    init(timerEngine: WebTimerEngine, networkService: LocalNetworkService = .shared) {
        self.webTimerEngine = timerEngine
        self.networkService = networkService
        setupEngine()
        setupLanguageSync()
    }

    private func setupEngine() {
        // 配置广播回调
        webTimerEngine.onBroadcast = { [weak self] jsonMessage in
            self?.networkService.broadcast(message: jsonMessage)
        }

        // 配置音频播放回调
        webTimerEngine.onPlaySound = { [weak self] soundName in
            self?.handlePlaySound(name: soundName)
        }
    }

    /// Web端是否已静音（独立于手机端）
    @Published var isMuted: Bool = false

    /// 切换静音状态
    func toggleMute() {
        isMuted.toggle()

        // 发送静音指令到 Web 端
        let json = "{\"type\": \"toggleMute\", \"muted\": \(isMuted)}"
        networkService.broadcast(message: json)
    }

    private func handlePlaySound(name: String) {
        // Web端静音由Web端本地控制，这里只广播声音指令
        // 广播声音指令到 Web 端
        let json = "{\"type\": \"playSound\", \"file\": \"\(name)\"}"
        networkService.broadcast(message: json)
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

        // 3. Timer State
        let statusStr: String
        switch webTimerEngine.status {
        case .running: statusStr = "running"
        case .paused: statusStr = "paused"
        case .stopped: statusStr = "stopped"
        case .idle: statusStr = "idle"
        }

        let json = """
        {
            "type": "update",
            "timeString": "\(webTimerEngine.timeString)",
            "progress": \(webTimerEngine.progress),
            "status": "\(statusStr)"
        }
        """
        connection.send(string: json)
    }

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
