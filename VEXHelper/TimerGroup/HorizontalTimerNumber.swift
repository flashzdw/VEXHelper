//
//  HorizontalTimerNumber.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/24.
//

import SwiftUI

/// 横屏模式下的倒计时数字显示组件
struct HorizontalTimerNumber: View {
    let timeString: String
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 150, weight: .bold, design: .default)) // 更大的字体
            .foregroundColor(.white)
            .monospacedDigit()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保在父视图中居中
    }
}

/// 横屏计时器视图
/// 包含背景、进度条、时间显示和静音按钮
struct LandscapeTimerView<Engine: TimerEngineProtocol>: View {
    // 计时器引擎
    @ObservedObject var timerEngine: Engine
    // 共享数据
    @ObservedObject var sharedData: SharedData
    
    // 颜色定义
    private let brightBlue = Color.blue
    private let darkGray = Color("AppDarkGray")
    
    // 自适应圆角：取屏幕短边的 12.5% 以适配各类机型的物理圆角
    private var adaptiveCornerRadius: CGFloat {
        min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.125
    }
    
    var body: some View {
        ZStack {
            // 背景 RoundedRectangle (color "darkGray", ignores safe area)
            RoundedRectangle(cornerRadius: adaptiveCornerRadius)
                .stroke(brightBlue.opacity(0.3), lineWidth: 22)
                .padding(14)
                .ignoresSafeArea()
            
            // 进度 RoundedRectangle (trim, color .blue, ignores safe area)
            ProgressRoundedRectangle(cornerRadius: adaptiveCornerRadius)
                .trim(from: 0, to: CGFloat(timerEngine.progress))
                .stroke(brightBlue, style: StrokeStyle(lineWidth: 25, lineCap: .round))
                // 注意：使用自定义的 ProgressRoundedRectangle 后，不再需要先旋转翻转了，因为它本来就是从顶部居中逆时针绘制的
                .padding(14)
                .ignoresSafeArea()
                .animation(.linear(duration: 0.1), value: timerEngine.progress)
            
            // 倒计时数字
            HorizontalTimerNumber(timeString: timerEngine.timeString)
            
            // 静音按钮 (位于左下角)
            VStack {
                Spacer()
                HStack {
                    muteButton(size: 30)
                        .padding(.bottom, 20)
                        .padding(.leading, 20)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// 创建静音按钮
    private func muteButton(size: CGFloat) -> some View {
        Button(action: {
            sharedData.isSoundEnabled.toggle()
            if !sharedData.isSoundEnabled {
                SoundsControlCenter.shared.stop()
            }
        }) {
            ZStack {
                Color.clear.frame(width: size * 1.5, height: size * 1.5)
                Image(systemName: sharedData.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: size))
                    .transaction(value: sharedData.isSoundEnabled) { $0.animation = nil }
            }
            .frame(width: size * 1.5, height: size * 1.5)
        }
    }
}

struct HorizontalTimerNumber_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LandscapeTimerView(
                timerEngine: SharedData.shared.phoneTimerEngine,
                sharedData: SharedData.shared
            )
        }
    }
}
