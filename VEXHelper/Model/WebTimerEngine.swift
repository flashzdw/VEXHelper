//
//  WebTimerEngine.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import Foundation
import Combine

/// Web端计时器引擎，负责Web端的计时逻辑
/// 与 PhoneTimerEngine 完全独立，拥有自己的状态
class WebTimerEngine: ObservableObject, TimerEngineProtocol, CountdownTimerDelegate {

    // MARK: - Published Properties

    /// 当前计时器状态
    @Published var status: TimerStatus

    /// 剩余时间（毫秒）
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

    /// 上一次广播的时间戳，用于节流 (Throttling)
    private var lastBroadcastTime: TimeInterval = 0

    // MARK: - Initialization

    init() {
        let isCustom = UserDefaults.standard.object(forKey: "isWebCustomTimer") as? Bool ?? false
        let initialTime: Int = (isCustom ? (UserDefaults.standard.object(forKey: "webTotalTime") as? Int ?? 60) : 60) * 1000
        
        self.status = .idle
        self.timeRemaining = initialTime
        self.progress = 1.0
        self.timeString = CountdownTimerCore.formatTimeString(timeRemaining: initialTime)
        self.lastBroadcastTime = 0
        
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
            let customTime = UserDefaults.standard.object(forKey: "webTotalTime") as? Int ?? 60
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

        // 只有状态数据变化时才继续
        guard currentStatusKey != lastBroadcastStatus else { return }
        
        // 节流处理 (Throttling)：限制最高广播频率为 20Hz (0.05秒)
        let now = Date().timeIntervalSince1970
        let isStatusChanged = !lastBroadcastStatus.contains(statusStr)
        
        // 如果是 running 状态，且状态本身没有发生切换（只是时间流逝），则应用节流
        if snapshot.status == .running && !isStatusChanged && (now - lastBroadcastTime) < 0.05 {
            return
        }

        lastBroadcastStatus = currentStatusKey
        lastBroadcastTime = now

        let json = TimerMessageFactory.update(snapshot: snapshot)
        onBroadcast?(json)
    }
}
