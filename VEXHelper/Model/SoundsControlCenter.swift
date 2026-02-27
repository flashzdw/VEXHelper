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
    
    var isRemoteAudioEnabled: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    
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
        if !SharedData.shared.soundSetting.isSoundEnabled {
            return
        }
        
        // 远程音频模式：广播指令，本地静音
        if isRemoteAudioEnabled {
            let json = "{\"type\": \"playSound\", \"file\": \"\(soundName)\"}"
            LocalNetworkService.shared.broadcast(message: json)
            return
        }
        
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "MP3") else {
            print("Sound file not found: \(soundName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Could not create audio player: \(error)")
        }
    }
    
    /// 停止播放
    func stop() {
        audioPlayer?.stop()
    }
}
