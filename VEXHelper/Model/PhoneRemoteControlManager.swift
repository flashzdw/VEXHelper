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
        // 手机模式下彻底独立，不再进行网络广播
        phoneTimerEngine.onBroadcast = { _ in
            // do nothing
        }

        // 配置音频播放回调，仅在本地处理
        phoneTimerEngine.onPlaySound = { [weak self] soundName in
            self?.handlePlaySound(name: soundName)
        }
    }

    /// 手机端是否已静音（独立于Web端）
    @Published var isMuted: Bool = false

    /// 切换静音状态
    func toggleMute() {
        isMuted.toggle()

        // 如果正在本地播放，也应该停止
        if isMuted {
            // SoundsControlCenter.shared.stop() // 如果有停止方法
        }
    }

    private func handlePlaySound(name: String) {
        // 如果已静音，直接返回，不播放任何声音
        if isMuted { return }

        // 手机模式下，始终且仅在本地播放声音
        DispatchQueue.main.async {
            SoundsControlCenter.shared.updateSoundPlayer(with: name)
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

    /// 发送初始状态给新连接 (语言)
    private func syncInitialState(to connection: WebSocketConnection) {
        // 1. Language
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        connection.send(string: "{\"type\": \"language\", \"lang\": \"\(lang)\"}")
        
        // 手机模式下不再同步计时器和静音状态到 Web
    }

    /// 同步当前语言到 Web 端
    func syncLanguage() {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let json = "{\"type\": \"language\", \"lang\": \"\(lang)\"}"
        networkService.broadcast(message: json)
    }
}
