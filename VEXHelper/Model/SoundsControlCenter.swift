//
//  SoundsControlCenter.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/24.
//

import Foundation
import AVFoundation

/// 音频控制中心，负责管理和播放应用内的音效
class SoundsControlCenter: NSObject {
    static let shared = SoundsControlCenter()

    // var isRemoteAudioEnabled: Bool = false // 已弃用，移至 RemoteControlManager

    /// 音频播放器缓存字典
    private var cachedPlayers: [String: AVAudioPlayer] = [:]

    private override init() {
        super.init()
        setupAudioSession()
    }

    /// 配置音频会话，确保后台播放和与其他音频的混合行为
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    /// 根据资源名称播放音效
    /// - Parameter soundName: 音频文件名（不含扩展名，默认MP3）
    func updateSoundPlayer(with soundName: String) {
        // 检查全局音效设置是否开启，如果未开启则直接返回不播放
        if !SharedData.shared.isSoundEnabled {
            return
        }

        // 复用缓存的播放器
        if let cachedPlayer = cachedPlayers[soundName] {
            cachedPlayer.currentTime = 0
            cachedPlayer.play()
            return
        }

        guard let url = Bundle.main.url(forResource: soundName, withExtension: "MP3") else {
            print("Sound file not found: \(soundName)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()

            // 添加到缓存
            cachedPlayers[soundName] = player
        } catch {
            print("Could not create audio player: \(error)")
        }
    }

    /// 停止播放
    func stop() {
        for player in cachedPlayers.values {
            player.stop()
        }
    }
}
