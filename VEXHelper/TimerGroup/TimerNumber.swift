//
//  TimerNumber.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/28.
//

import SwiftUI

/// 倒计时数字显示组件
/// 用于显示大字体的倒计时时间
struct TimerNumber: View {
    let timeString: String
    
    var body: some View {
        Text(timeString)
            // 设置字体大小为 80，粗体，默认设计
            .font(.system(size: 80, weight: .bold, design: .default))
            .foregroundColor(.white)
            // 使用等宽数字，避免倒计时过程中数字宽度变化导致跳动
            .monospacedDigit()
    }
}

/// 竖屏模式下的圆形倒计时视图
/// 包含进度圆环、时间显示和静音控制
struct PortraitTimerView: View {
    // 传入的计时器引擎对象
    @ObservedObject var timerEngine: PhoneTimerEngine
    // 共享数据对象，用于控制静音状态
    @ObservedObject var sharedData: SharedData
    
    // 定义颜色常量
    private let brightBlue = Color.blue
    private let darkGray = Color("AppDarkGray")
    
    var body: some View {
        ZStack {
            // 背景圆环 (下层)
            Circle()
                .stroke(brightBlue.opacity(0.3), lineWidth: 18)
                .frame(width: 300, height: 300)
            
            // 进度圆环 (上层)
            // 根据 timerEngine.progress 显示进度
            Circle()
                .trim(from: 0, to: CGFloat(timerEngine.progress))
                .stroke(brightBlue, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .frame(width: 300, height: 300)
                // 旋转 -90 度，让进度从顶部开始
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timerEngine.progress)
            
            // 内部垂直布局
            VStack(spacing: 10) {
                // 倒计时文字
                TimerNumber(timeString: timerEngine.timeString)
                
                // 音效状态按钮
                muteButton(size: 24)
                    .frame(height: 30) // 固定高度防止布局抖动
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// 创建静音按钮
    /// - Parameter size: 图标的大小
    /// - Returns: 静音按钮视图
    private func muteButton(size: CGFloat) -> some View {
        Button(action: {
            // 切换静音设置
            sharedData.soundSetting.isSoundEnabled.toggle()
            // 如果切换为静音，立即停止当前播放的声音
            if !sharedData.soundSetting.isSoundEnabled {
                SoundsControlCenter.shared.stop()
            }
        }) {
            ZStack {
                // 透明背景，扩大点击区域
                Color.clear.frame(width: size * 1.5, height: size * 1.5)
                
                // 根据状态显示不同图标
                Image(systemName: sharedData.soundSetting.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: size))
                    .transaction(value: sharedData.soundSetting.isSoundEnabled) { $0.animation = nil }
            }
            // 强制固定 Frame 防止图标切换时大小变化导致抖动
            .frame(width: size * 1.5, height: size * 1.5)
        }
    }
}

struct TimerNumber_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            // 预览时注入模拟数据
            PortraitTimerView(
                timerEngine: SharedData.shared.phoneTimerEngine,
                sharedData: SharedData.shared
            )
        }
    }
}
