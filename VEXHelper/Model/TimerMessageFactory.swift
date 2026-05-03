//
//  TimerMessageFactory.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/05/04.
//

import Foundation

/// 统一封装计时器相关的状态和计算结果
struct TimerSnapshot: Equatable {
    var timeRemaining: Int
    var timeString: String
    var progress: Double
    var status: TimerStatus
}

/// 统一消息生成工厂，负责序列化需要发送给 Web 端的各种状态和指令
enum TimerMessageFactory {
    
    /// 将 TimerStatus 转换为前端协议中所需的字符串
    static func statusString(for status: TimerStatus) -> String {
        switch status {
        case .running: return "running"
        case .paused: return "paused"
        case .stopped: return "stopped"
        case .idle: return "idle"
        }
    }
    
    /// 生成包含完整状态信息的 update 消息
    static func update(snapshot: TimerSnapshot) -> String {
        let statusStr = statusString(for: snapshot.status)
        return """
        {
            "type": "update",
            "timeString": "\(snapshot.timeString)",
            "progress": \(snapshot.progress),
            "status": "\(statusStr)"
        }
        """
    }
    
    /// 生成 toggleMute 指令消息
    static func toggleMute(isMuted: Bool) -> String {
        return "{\"type\": \"toggleMute\", \"muted\": \(isMuted)}"
    }
    
    /// 生成语言切换指令消息
    static func language(lang: String) -> String {
        return "{\"type\": \"language\", \"lang\": \"\(lang)\"}"
    }
    
    /// 生成播放音效指令消息
    static func playSound(name: String) -> String {
        return "{\"type\": \"playSound\", \"file\": \"\(name)\"}"
    }
}
