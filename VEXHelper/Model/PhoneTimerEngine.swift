//
//  PhoneTimerEngine.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import Foundation
import Combine

/// 手机端计时器引擎，负责手机端的核心计时逻辑
/// 与 WebTimerEngine 完全独立，拥有自己的状态
class PhoneTimerEngine: ObservableObject, TimerEngineProtocol, CountdownTimerDelegate {

    // MARK: - Published Properties

    /// 当前计时器状态
    @Published var status: TimerStatus

    /// 剩余时间（毫秒）
    /// 确保在主线程更新以保证 UI 响应流畅
    @Published var timeRemaining: Int

    /// 进度 (0.0 - 1.0)，用于进度条显示
    @Published var progress: Double

    /// 格式化的时间字符串 "m:ss"
    @Published var timeString: String

    // MARK: - Callbacks

    /// 广播回调：(JSON String) -> Void
    var onBroadcast: ((String) -> Void)?

    /// 播放声音回调：(Sound Name) -> Void
    var onPlaySound: ((String) -> Void)?

    // MARK: - Private Properties

    private var core: CountdownTimerCore!
    
    /// 上一次广播的状态缓存，用于优化广播频率
    private var lastBroadcastStatus: String = ""

    // MARK: - Initialization

    init() {
        let isCustom = UserDefaults.standard.object(forKey: "isPhoneCustomTimer") as? Bool ?? false
        let initialTime: Int = (isCustom ? (UserDefaults.standard.object(forKey: "phoneTotalTime") as? Int ?? 60) : 60) * 1000
        
        self.status = .idle
        self.timeRemaining = initialTime
        self.progress = 1.0
        self.timeString = CountdownTimerCore.formatTimeString(timeRemaining: initialTime)
        
        self.core = CountdownTimerCore(totalTime: initialTime, isCustomTimer: isCustom)
        self.core.delegate = self
    }

    // MARK: - Public Methods

    /// 更新是否为自定义模式，如果是默认模式则强制设为 60s
    func updateIsCustom(_ isCustom: Bool) {
        core.isCustomTimer = isCustom
        if !isCustom {
            updateTotalTime(60)
        } else {
            let customTime = UserDefaults.standard.object(forKey: "phoneTotalTime") as? Int ?? 60
            updateTotalTime(customTime)
        }
    }

    /// 更新总时间配置
    func updateTotalTime(_ seconds: Int) {
        core.totalTime = seconds * 1000
    }

    /// 开始或继续计时
    func start() {
        core.start()
    }

    /// 暂停计时
    func pause() {
        core.pause()
    }

    /// 停止计时（手动触发）
    func stop() {
        core.stop()
    }

    /// 重置计时器
    func reset() {
        core.reset()
    }
    
    // MARK: - CountdownTimerDelegate
    
    func timerDidUpdateSnapshot(_ snapshot: TimerSnapshot) {
        self.status = snapshot.status
        self.timeRemaining = snapshot.timeRemaining
        self.progress = snapshot.progress
        self.timeString = snapshot.timeString
        
        broadcastState(snapshot: snapshot)
    }
    
    func timerDidTriggerSound(_ soundName: String) {
        onPlaySound?(soundName)
    }

    // MARK: - Private Methods

    private func broadcastState(snapshot: TimerSnapshot) {
        let statusStr = TimerMessageFactory.statusString(for: snapshot.status)
        let currentStatusKey = "\(statusStr)_\(snapshot.timeString)_\(snapshot.progress)"

        guard currentStatusKey != lastBroadcastStatus else { return }
        lastBroadcastStatus = currentStatusKey

        let json = TimerMessageFactory.update(snapshot: snapshot)
        onBroadcast?(json)
    }
}
