//
//  SharedData.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import SwiftUI
import Combine

/// 菜单隐藏模式枚举
enum MenuVisibilityMode: String, CaseIterable, Identifiable {
    case duringCounting // 计时过程中隐藏（默认）
    case afterStart     // 开始计时后隐藏（直到重置）
    case alwaysShow     // 不隐藏（全屏除外）
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .duringCounting:
            return NSLocalizedString("Hide during counting", comment: "Menu visibility mode")
        case .afterStart:
            return NSLocalizedString("Hide after start", comment: "Menu visibility mode")
        case .alwaysShow:
            return NSLocalizedString("Always show", comment: "Menu visibility mode")
        }
    }
}

/// 全局共享数据，用于管理应用级设置和状态
class SharedData: ObservableObject {
    static let shared = SharedData()
    
    /// 计时器设置
    @Published var timerSetting: TimerSetting = TimerSetting()
    
    /// 音效设置
    @Published var soundSetting: SoundSetting = SoundSetting()
    
    /// 菜单隐藏模式设置 (使用 UserDefaults 持久化)
    @AppStorage("menuVisibilityMode") var menuVisibilityMode: MenuVisibilityMode = .duringCounting
    
    private init() {}
}

/// 计时器配置模型
struct TimerSetting {
    /// 比赛总时长，默认为60秒
    var totalTime: Int = 60
}

/// 音效配置模型
struct SoundSetting {
    /// 是否启用音效
    var isSoundEnabled: Bool = true
}
