//
//  SharedData.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import SwiftUI
import Combine

/// 全局共享数据，用于管理应用级设置和状态
class SharedData: ObservableObject {
    static let shared = SharedData()
    
    /// 计时器设置
    @Published var timerSetting: TimerSetting = TimerSetting()
    
    /// 音效设置
    @Published var soundSetting: SoundSetting = SoundSetting()
    
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
