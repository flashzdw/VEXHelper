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

    /// 是否仅远程播放音频
    @Published var isRemoteAudioEnabled: Bool = true

    /// 切换静音状态
    func toggleMute() {
        isMuted.toggle()

        // 发送静音指令到 Web 端
        networkService.broadcast(message: TimerMessageFactory.toggleMute(isMuted: isMuted))
    }

    private func handlePlaySound(name: String) {
        // 如果已静音，直接返回，不播放任何声音
        if isMuted { return }

        // 始终广播声音指令到 Web 端
        networkService.broadcast(message: TimerMessageFactory.playSound(name: name))

        // 决定是否在手机本地播放声音
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
        connection.send(string: TimerMessageFactory.language(lang: lang))

        // 2. Mute State
        connection.send(string: TimerMessageFactory.toggleMute(isMuted: isMuted))

        // 3. Timer State
        let snapshot = TimerSnapshot(
            timeRemaining: webTimerEngine.timeRemaining,
            timeString: webTimerEngine.timeString,
            progress: webTimerEngine.progress,
            status: webTimerEngine.status
        )
        connection.send(string: TimerMessageFactory.update(snapshot: snapshot))
    }

    /// 同步当前语言到 Web 端
    func syncLanguage() {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        networkService.broadcast(message: TimerMessageFactory.language(lang: lang))

        // 同时同步静音状态
        networkService.broadcast(message: TimerMessageFactory.toggleMute(isMuted: isMuted))
    }
}
