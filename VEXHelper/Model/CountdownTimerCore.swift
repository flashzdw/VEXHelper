//
//  CountdownTimerCore.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/05/04.
//

import Foundation

protocol CountdownTimerDelegate: AnyObject {
    /// 倒计时状态发生改变时回调，保证在主线程调用
    func timerDidUpdateSnapshot(_ snapshot: TimerSnapshot)
    
    /// 触发需要播放的音效
    func timerDidTriggerSound(_ soundName: String)
}

/// 抽取双端共享的倒计时核心计算与状态流转逻辑
class CountdownTimerCore {
    weak var delegate: CountdownTimerDelegate?
    
    // MARK: - Configurations
    
    /// 是否为自定义计时器 (跳过中间提示音)
    var isCustomTimer: Bool {
        didSet {
            // 如果不处于 idle 状态，通常不立即生效，但可以根据需求修改
        }
    }
    
    /// 总时长（毫秒）
    var totalTime: Int {
        didSet {
            if currentSnapshot.status == .idle {
                resetTimeData()
            }
        }
    }
    
    // MARK: - Internal State
    
    /// 当前计时器快照
    private(set) var currentSnapshot: TimerSnapshot
    
    private var timer: Timer?
    private var endTime: Date?
    private var lastTickTimeRemaining: Int
    
    init(totalTime: Int, isCustomTimer: Bool) {
        self.totalTime = totalTime
        self.isCustomTimer = isCustomTimer
        self.lastTickTimeRemaining = totalTime
        
        self.currentSnapshot = TimerSnapshot(
            timeRemaining: totalTime,
            timeString: CountdownTimerCore.formatTimeString(timeRemaining: totalTime),
            progress: 1.0,
            status: .idle
        )
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Actions
    
    /// 开始或继续计时
    func start() {
        if currentSnapshot.status == .running { return }
        
        if currentSnapshot.status == .paused {
            // 从暂停状态恢复
            startTimer()
        } else {
            // 新的开始
            resetTimeData()
            startTimer()
        }
        
        updateStatus(.running)
        delegate?.timerDidTriggerSound("Start")
    }
    
    /// 暂停计时
    func pause() {
        guard currentSnapshot.status == .running else { return }
        
        delegate?.timerDidTriggerSound("Stop")
        stopTimer()
        updateTimeRemainingFromDate() // 确保最后的时间准确
        updateStatus(.paused)
    }
    
    /// 停止计时
    func stop() {
        delegate?.timerDidTriggerSound("Over")
        stopTimer()
        updateStatus(.stopped)
    }
    
    /// 重置计时
    func reset() {
        stopTimer()
        resetTimeData()
        updateStatus(.idle)
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer?.invalidate()
        
        let now = Date()
        let duration = TimeInterval(currentSnapshot.timeRemaining) / 1000.0
        endTime = now.addingTimeInterval(duration)
        
        lastTickTimeRemaining = currentSnapshot.timeRemaining
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard endTime != nil else { return }
        
        updateTimeRemainingFromDate()
        
        if currentSnapshot.timeRemaining <= 0 {
            handleTimerFinished()
            return
        }
        
        checkSoundTriggers()
        lastTickTimeRemaining = currentSnapshot.timeRemaining
    }
    
    private func updateTimeRemainingFromDate() {
        guard let endTime = endTime else { return }
        
        let remainingSeconds = endTime.timeIntervalSinceNow
        let newTimeRemaining = max(0, Int(remainingSeconds * 1000))
        
        if newTimeRemaining != currentSnapshot.timeRemaining {
            applyNewTimeRemaining(newTimeRemaining)
        }
    }
    
    private func applyNewTimeRemaining(_ newTimeRemaining: Int) {
        if Thread.isMainThread {
            self.currentSnapshot.timeRemaining = newTimeRemaining
            self.currentSnapshot.progress = Double(newTimeRemaining) / Double(self.totalTime)
            self.currentSnapshot.timeString = CountdownTimerCore.formatTimeString(timeRemaining: newTimeRemaining)
            self.notifySnapshotUpdated()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentSnapshot.timeRemaining = newTimeRemaining
                self.currentSnapshot.progress = Double(newTimeRemaining) / Double(self.totalTime)
                self.currentSnapshot.timeString = CountdownTimerCore.formatTimeString(timeRemaining: newTimeRemaining)
                self.notifySnapshotUpdated()
            }
        }
    }
    
    private func updateStatus(_ newStatus: TimerStatus) {
        if currentSnapshot.status != newStatus {
            if Thread.isMainThread {
                self.currentSnapshot.status = newStatus
                self.notifySnapshotUpdated()
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.currentSnapshot.status = newStatus
                    self.notifySnapshotUpdated()
                }
            }
        }
    }
    
    private func handleTimerFinished() {
        stopTimer()
        
        if Thread.isMainThread {
            self.currentSnapshot.timeRemaining = 0
            self.currentSnapshot.progress = 0.0
            self.currentSnapshot.timeString = "0:00"
            self.currentSnapshot.status = .stopped
            self.notifySnapshotUpdated()
            self.delegate?.timerDidTriggerSound("Over")
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentSnapshot.timeRemaining = 0
                self.currentSnapshot.progress = 0.0
                self.currentSnapshot.timeString = "0:00"
                self.currentSnapshot.status = .stopped
                self.notifySnapshotUpdated()
                self.delegate?.timerDidTriggerSound("Over")
            }
        }
    }
    
    private func resetTimeData() {
        let newTotal = totalTime
        if Thread.isMainThread {
            self.currentSnapshot.timeRemaining = newTotal
            self.currentSnapshot.progress = 1.0
            self.currentSnapshot.timeString = CountdownTimerCore.formatTimeString(timeRemaining: newTotal)
            self.lastTickTimeRemaining = newTotal
            self.notifySnapshotUpdated()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentSnapshot.timeRemaining = newTotal
                self.currentSnapshot.progress = 1.0
                self.currentSnapshot.timeString = CountdownTimerCore.formatTimeString(timeRemaining: newTotal)
                self.lastTickTimeRemaining = newTotal
                self.notifySnapshotUpdated()
            }
        }
    }
    
    private func notifySnapshotUpdated() {
        delegate?.timerDidUpdateSnapshot(currentSnapshot)
    }
    
    private func checkSoundTriggers() {
        if isCustomTimer { return }
        
        let timeRemaining = currentSnapshot.timeRemaining
        if lastTickTimeRemaining > 35000 && timeRemaining <= 35000 {
            delegate?.timerDidTriggerSound("Change")
        }
        
        if lastTickTimeRemaining > 25000 && timeRemaining <= 25000 {
            delegate?.timerDidTriggerSound("Change")
        }
    }
    
    static func formatTimeString(timeRemaining: Int) -> String {
        let seconds = Int(ceil(Double(timeRemaining) / 1000.0))
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
