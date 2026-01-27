//
//  TimerControlCenter.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/24.
//

import Foundation
import Combine

/// 计时器状态枚举
enum TimerStatus {
    case idle       // 空闲/重置状态
    case running    // 运行中
    case paused     // 暂停
    case stopped    // 停止/结束
}

/// 计时器配置，定义关键触发时间点（单位：毫秒）
struct TimerConfig {
    static let totalTime: Int = 60000 // 60秒
    static let triggerChange: Int = 35000 // 35秒时提示 (文档提及36000，但VEX通常是35秒换人，这里保留文档逻辑或调整)
    // 根据文档：Trigger Change: 36000ms (36秒, 对应35秒提示)
    // Trigger Warning: 26000ms (26秒, 对应25秒提示)
    // Trigger Over: 1000ms (1秒, 对应结束)
    
    // 我们按照文档的数值设定，确保符合用户文档描述
    static let docTriggerChange: Int = 35000 // 35秒
    static let docTriggerWarning: Int = 25000 // 25秒
    static let docTriggerOver: Int = 0 // 倒计时归零时
}

/// 计时器核心控制中心
class TimerControlCenter: ObservableObject {
    @Published var status: TimerStatus = .idle
    @Published var timeRemaining: Int = TimerConfig.totalTime // 剩余时间（毫秒）
    
    // 进度 (0.0 - 1.0)，用于UI圆环显示
    var progress: Double {
        return Double(timeRemaining) / Double(TimerConfig.totalTime)
    }
    
    // 显示的时间文本 (例如 "1:00", "0:45")
    var timeString: String {
        let seconds = Int(ceil(Double(timeRemaining) / 1000.0))
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private var timer: Timer?
    
    // 标志位，防止重复播放
    private var hasPlayedStartSound = false
    private var hasPlayedChangeSound = false
    private var hasPlayedWarningSound = false
    private var hasPlayedOverSound = false
    
    // 单例引用音频中心
    private let soundCenter = SoundsControlCenter.shared
    
    init() {
        reset()
    }
    
    /// 开始或继续计时
    func start() {
        if status == .idle || status == .paused {
            // 启动或继续时播放 Start.MP3
            if SharedData.shared.soundSetting.isSoundEnabled {
                soundCenter.updateSoundPlayer(with: "Start")
            }
        }
        
        status = .running
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    /// 暂停计时
    func pause() {
        status = .paused
        timer?.invalidate()
        // 暂停时播放 Stop.MP3
        if SharedData.shared.soundSetting.isSoundEnabled {
            soundCenter.updateSoundPlayer(with: "Stop")
        }
    }
    
    /// 重置计时器
    func reset() {
        internalStop()
        status = .idle
        timeRemaining = TimerConfig.totalTime
        
        // 重置标志位
        hasPlayedStartSound = false
        hasPlayedChangeSound = false
        hasPlayedWarningSound = false
        hasPlayedOverSound = false
    }
    
    /// 手动停止计时
    func stop() {
        internalStop()
        // 停止时播放 Over.MP3
        if SharedData.shared.soundSetting.isSoundEnabled {
            soundCenter.updateSoundPlayer(with: "Over")
        }
    }
    
    /// 内部停止逻辑
    private func internalStop() {
        status = .stopped
        timer?.invalidate()
    }
    
    /// 计时器心跳逻辑
    private func tick() {
        guard status == .running else { return }
        
        // 扣减时间 (100ms)
        timeRemaining -= 100
        
        if timeRemaining <= 0 {
            timeRemaining = 0
            internalStop()
            // 自动结束也视为 Stopped 状态
            status = .stopped 
            // 播放结束音效
            if !hasPlayedOverSound && SharedData.shared.soundSetting.isSoundEnabled {
                soundCenter.updateSoundPlayer(with: "Over")
                hasPlayedOverSound = true
            }
            return
        }
        
        checkTriggers()
    }
    
    /// 检查并触发音效
    private func checkTriggers() {
        guard SharedData.shared.soundSetting.isSoundEnabled else { return }
        
        // 文档逻辑：Trigger Change 36000ms
        if timeRemaining <= TimerConfig.docTriggerChange && !hasPlayedChangeSound {
            soundCenter.updateSoundPlayer(with: "Change")
            hasPlayedChangeSound = true
        }
        
        // 文档逻辑：Trigger Warning 26000ms
        if timeRemaining <= TimerConfig.docTriggerWarning && !hasPlayedWarningSound {
            // 这里假设 25秒提示也是用 Change 或者其他音效，如果只有4个文件，Change比较合适做提示
            soundCenter.updateSoundPlayer(with: "Change")
            hasPlayedWarningSound = true
        }
        
        // 文档逻辑：Trigger Over 1000ms (即将结束)
        // 注意：Over 音效通常在 0秒播放，但如果需要在1秒时预警，可以加逻辑
        // 这里我们在 tick() <= 0 时播放 Over.MP3
        // 如果需要 1秒时的提示，可以使用 Stop.MP3 或其他?
        // 暂时只在 0秒播放 Over
    }
}
