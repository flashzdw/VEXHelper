//
//  TimerEngine.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import Foundation
import Combine

/// 计时器状态枚举
enum TimerStatus {
    case idle       // 空闲
    case running    // 运行中
    case paused     // 暂停
    case stopped    // 停止
}

/// 计时器引擎，负责核心计时逻辑
/// 优化：使用 Date 和 endTime 计算剩余时间，避免 timer 精度累积误差
class TimerEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前计时器状态
    @Published var status: TimerStatus = .idle
    
    /// 剩余时间（毫秒），默认 60000ms (1分钟)
    /// 确保在主线程更新以保证 UI 响应流畅
    @Published var timeRemaining: Int = 60000
    
    /// 进度 (0.0 - 1.0)，用于进度条显示
    @Published var progress: Double = 1.0
    
    /// 格式化的时间字符串 "m:ss"
    @Published var timeString: String = "1:00"
    
    // MARK: - Callbacks
    
    /// 广播回调：(JSON String) -> Void
    var onBroadcast: ((String) -> Void)?
    
    /// 播放声音回调：(Sound Name) -> Void
    var onPlaySound: ((String) -> Void)?
    
    // MARK: - Private Properties
    
    /// 核心计时器 (NSTimer)
    private var timer: Timer?
    
    /// 目标结束时间，用于精确计算剩余时长
    private var endTime: Date?
    
    /// 总时间常量 (60秒 = 60000毫秒)
    private let totalTime: Int = 60000
    
    /// 上一次 tick 的剩余时间，用于检测声音触发阈值（防止跳帧错过）
    private var lastTickTimeRemaining: Int = 60000
    
    // MARK: - Initialization
    
    init() {
        updateTimeString()
    }
    
    // MARK: - Public Methods
    
    /// 开始或继续计时
    func start() {
        if status == .running { return }
        
        if status == .paused {
            // 从暂停状态恢复：基于当前剩余时间重新计算 endTime
            startTimer(resuming: true)
        } else {
            // 新的开始：重置所有数据
            resetTimeData()
            startTimer(resuming: false)
        }
        
        status = .running
        
        // 播放开始音效
        playSound(name: "Start")
    }
    
    /// 暂停计时
    func pause() {
        guard status == .running else { return }
        
        // 播放暂停音效
        playSound(name: "Stop")
        
        // 停止计时器
        stopTimer()
        
        // 最后更新一次时间，确保暂停时显示的数据是准确的
        updateTimeRemainingFromDate()
        
        status = .paused
    }
    
    /// 停止计时（手动触发）
    func stop() {
        // 播放结束音效
        playSound(name: "Over")
        
        stopTimer()
        status = .stopped
        
        // 根据需求，停止时不自动重置时间，需手动点击重置按钮
        // resetTimeData()
    }
    
    /// 重置计时器
    func reset() {
        stopTimer()
        status = .idle
        resetTimeData()
        broadcastState()
    }
    
    // MARK: - Private Methods
    
    /// 启动计时器逻辑
    /// - Parameter resuming: 是否是从暂停恢复（影响 endTime 的计算基准）
    private func startTimer(resuming: Bool) {
        // 清理旧的 timer
        stopTimer()
        
        // 计算 endTime
        // 逻辑：endTime = 当前时间 + (剩余毫秒数 / 1000.0)
        let now = Date()
        let duration = TimeInterval(timeRemaining) / 1000.0
        endTime = now.addingTimeInterval(duration)
        
        // 记录启动时的剩余时间
        lastTickTimeRemaining = timeRemaining
        
        // 创建 Timer，间隔设为 0.016s (约 60 FPS) 以获得平滑的 UI 更新
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        // 将 Timer 加入 Common 模式，防止 ScrollView 滚动时计时停止
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    /// 停止并清理计时器
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        endTime = nil
    }
    
    /// 计时器每帧调用的方法
    private func tick() {
        guard endTime != nil else { return }
        
        // 1. 更新剩余时间
        updateTimeRemainingFromDate()
        
        // 2. 检查是否结束
        if timeRemaining <= 0 {
            handleTimerFinished()
            return
        }
        
        // 3. 检查声音触发点（区间检查防止错过）
        checkSoundTriggers()
        
        // 4. 更新上一帧时间记录
        lastTickTimeRemaining = timeRemaining
        
        // 5. 广播状态
        broadcastState()
    }
    
    private func broadcastState() {
        let statusStr: String
        switch status {
        case .running: statusStr = "running"
        case .paused: statusStr = "paused"
        case .stopped: statusStr = "stopped"
        case .idle: statusStr = "idle"
        }
        
        let json = """
        {
            "type": "update",
            "timeString": "\(timeString)",
            "progress": \(progress),
            "status": "\(statusStr)"
        }
        """
        onBroadcast?(json)
    }
    
    /// 根据 endTime 和当前时间计算剩余毫秒数
    private func updateTimeRemainingFromDate() {
        guard let endTime = endTime else { return }
        
        // 计算时间差：endTime - now
        let remainingSeconds = endTime.timeIntervalSinceNow
        
        // 转换为毫秒并确保不小于 0
        let newTimeRemaining = max(0, Int(remainingSeconds * 1000))
        
        // 只有变化时才通知 UI 更新（虽然 16ms 基本都会变）
        if newTimeRemaining != timeRemaining {
            // 确保在主线程赋值
            if Thread.isMainThread {
                self.timeRemaining = newTimeRemaining
                self.updateProgress()
                self.updateTimeString()
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.timeRemaining = newTimeRemaining
                    self.updateProgress()
                    self.updateTimeString()
                }
            }
        }
    }
    
    /// 检查并在特定时间点触发音效
    private func checkSoundTriggers() {
        // 使用区间判断：上一帧时间 > 阈值 && 当前时间 <= 阈值
        
        // 35秒触发点 (35000ms)
        if lastTickTimeRemaining > 35000 && timeRemaining <= 35000 {
            playSound(name: "Change")
        }
        
        // 25秒触发点 (25000ms)
        if lastTickTimeRemaining > 25000 && timeRemaining <= 25000 {
            playSound(name: "Change")
        }
    }
    
    private func playSound(name: String) {
        onPlaySound?(name)
    }
    
    /// 计时结束处理
    private func handleTimerFinished() {
        stopTimer()
        
        // 强制归零状态
        timeRemaining = 0
        updateProgress()
        updateTimeString()
        status = .stopped
        
        // 播放结束音效
        playSound(name: "Over")
    }
    
    /// 重置所有时间相关数据到初始状态
    private func resetTimeData() {
        timeRemaining = totalTime
        lastTickTimeRemaining = totalTime
        progress = 1.0
        updateTimeString()
    }
    
    /// 更新进度条 (0.0 - 1.0)
    private func updateProgress() {
        progress = Double(timeRemaining) / Double(totalTime)
    }
    
    /// 更新时间字符串显示
    private func updateTimeString() {
        // 向上取整秒数，符合常规倒计时逻辑
        let seconds = Int(ceil(Double(timeRemaining) / 1000.0))
        let m = seconds / 60
        let s = seconds % 60
        timeString = String(format: "%d:%02d", m, s)
    }
}
