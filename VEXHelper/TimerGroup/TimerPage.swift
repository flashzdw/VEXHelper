//
//  TimerPage.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/24.
//

import SwiftUI

struct TimerPage: View {
    @StateObject var timerCenter = TimerControlCenter()
    // 监听 SharedData 变化，确保静音状态实时更新
    @ObservedObject var sharedData = SharedData.shared
    @State private var isFullscreen: Bool = false
    
    // 自定义颜色
    let darkGray = Color("darkGray")
    let brightBlue = Color.blue // 使用系统蓝或自定义亮蓝
    
    // 自定义形状用于部分圆角
    struct CornerRadiusShape: Shape {
        var radius: CGFloat = .infinity
        var corners: UIRectCorner = .allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }
    
    var body: some View {
        ZStack {
            // 背景色
            darkGray.edgesIgnoringSafeArea(.all)
            
            if isFullscreen {
                // 全屏模式 (旋转视图)
                fullScreenView
            } else {
                // 普通模式
                portraitView
            }
        }
        // 确保状态栏样式正确（如果需要）
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Portrait View
    var portraitView: some View {
        VStack {
            // 顶部控制栏
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        isFullscreen = true
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right") // 类似扩展图标
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(brightBlue)
                        .clipShape(Circle())
                }
                .padding(.top, 40) // 适配顶部安全区
                .padding(.trailing, 20)
            }
            
            Spacer()
            
            // 中间圆环倒计时
            ZStack {
                // 背景圆环 (下层)
                Circle()
                    .stroke(brightBlue.opacity(0.3), lineWidth: 18) // 稍微细一点
                    .frame(width: 300, height: 300)
                
                // 进度圆环 (上层)
                Circle()
                    .trim(from: 0, to: CGFloat(timerCenter.progress))
                    .stroke(brightBlue, style: StrokeStyle(lineWidth: 22, lineCap: .round)) // 稍微粗一点 (增加2-4像素差异)
                    .frame(width: 300, height: 300)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timerCenter.progress)
                
                VStack(spacing: 10) {
                    // 倒计时文字
                    TimerNumber(timeString: timerCenter.timeString)
                    
                    // 音效状态图标
                    muteButton(size: 24)
                        .frame(height: 30) // 固定高度防止抖动
                }
            }
            
            Spacer()
            
            // 底部控制按钮
            HStack(spacing: 50) {
                switch timerCenter.status {
                case .idle:
                    // 初始状态：显示播放按钮
                    controlButton(iconName: "play.fill", action: {
                        timerCenter.start()
                    })
                    
                case .running:
                    // 运行中：显示暂停（左）和停止（右）
                    controlButton(iconName: "pause.fill", action: {
                        timerCenter.pause()
                    })
                    controlButton(iconName: "square.fill", action: {
                        timerCenter.stop()
                    })
                    
                case .paused:
                    // 暂停：显示重置（左）和继续（右）
                    controlButton(iconName: "arrow.triangle.2.circlepath", action: {
                        timerCenter.reset()
                    })
                    controlButton(iconName: "play.fill", action: {
                        timerCenter.start()
                    })
                    
                case .stopped:
                    // 停止/结束：显示重置按钮
                    controlButton(iconName: "arrow.triangle.2.circlepath", action: {
                        timerCenter.reset()
                    })
                }
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Fullscreen View (Rotated)
    var fullScreenView: some View {
        ZStack {
            // 背景轨迹 (深灰色或透明，显示完整轮廓)
            // 蓝色边框下应有另一层颜色，这里使用 darkGray
            RoundedRectangle(cornerRadius: 40)
                .stroke(darkGray, lineWidth: 22)
                .padding(0)
                .ignoresSafeArea()

            // 蓝色进度边框 (随时间减少)
            RoundedRectangle(cornerRadius: 50)
                .trim(from: 0, to: CGFloat(timerCenter.progress))
                .stroke(brightBlue, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .padding(12)
                .ignoresSafeArea()
                .animation(.linear(duration: 0.1), value: timerCenter.progress)
            
            // 退出全屏按钮 (右上角贴边样式)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isFullscreen = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(15)
                            .background(Color.black.opacity(0.5))
                            .clipShape(CornerRadiusShape(radius: 29, corners: .bottomLeft))
                            .rotationEffect(.degrees(180))
                    }
                }
                // 使用 padding 偏移以紧贴蓝色边框内侧 (边框宽22，一半在内侧为11)
                // 忽略安全区域后，需要手动添加边距以避免被边框遮挡或重叠
                .padding(.top, 25)
                .padding(.trailing, 25)
                
                Spacer()
            }
            .ignoresSafeArea()
            
            // 中间大数字 (旋转)
            VStack(spacing: 20) {
                HorizontalTimerNumber(timeString: timerCenter.timeString)
            }
            
            // 横屏静音按钮 (移动到屏幕右下角)
            // 在旋转后的坐标系中，屏幕右下角对应的是 UI 的左下角 (如果UI是逆时针旋转) 或者 左上角?
            // 让我们使用绝对定位的逻辑。
            // 屏幕物理右下角 -> UI 旋转90度后的位置。
            // 假设 HorizontalTimerNumber 是 .rotationEffect(.degrees(90))
            // 那么整个 UI 是顺时针旋转90度。
            // 物理右下角 -> UI 的左下角。
            VStack {
                Spacer()
                HStack {
                    muteButton(size: 30)
                        .rotationEffect(.degrees(90)) // 按钮自身旋转以保持图标方向正确
                        .padding(.bottom, 40)
                        .padding(.leading, 40) // 在UI左下角
                    Spacer()
                }
            }
            
            // 左侧控制按钮 (对应逻辑上的底部，旋转90度)
            HStack {
                VStack(spacing: 30) {
                    Spacer() // 添加 Spacer 使按钮垂直居中
                    switch timerCenter.status {
                    case .idle:
                        // 初始状态：显示播放按钮 (旋转90度，指向下方)
                        controlButton(iconName: "play.fill", rotated: true, action: {
                            timerCenter.start()
                        })
                        
                    case .running:
                        // 运行中：显示暂停（上/左）和停止（下/右） -> 镜像翻转位置
                        // 原来：停止(上), 暂停(下)。
                        // 镜像后要求符合直觉：通常上方对应左侧，下方对应右侧?
                        // 让我们调整为：暂停(上), 停止(下)。
                        controlButton(iconName: "pause.fill", rotated: true, action: {
                            timerCenter.pause()
                        })
                        controlButton(iconName: "square.fill", rotated: true, action: {
                            timerCenter.stop()
                        })
                        
                    case .paused:
                        // 暂停：显示重置（上/左）和继续（下/右） -> 镜像翻转位置
                        // 原来：继续(上), 重置(下)。
                        // 调整为：重置(上), 继续(下)。
                        controlButton(iconName: "xmark", rotated: true, action: {
                            timerCenter.reset()
                        })
                        controlButton(iconName: "play.fill", rotated: true, action: {
                            timerCenter.start()
                        })
                        
                    case .stopped:
                        // 停止：显示重置
                        controlButton(iconName: "arrow.triangle.2.circlepath", rotated: true, action: {
                            timerCenter.reset()
                        })
                    }
                    Spacer() // 添加 Spacer 使按钮垂直居中
                }
                .padding(.leading, 40)
                
                Spacer()
            }
        }
    }
    
    // 辅助函数：静音按钮
    func muteButton(size: CGFloat) -> some View {
        Button(action: {
            sharedData.soundSetting.isSoundEnabled.toggle()
            // 如果切换为静音，立即停止播放
            if !sharedData.soundSetting.isSoundEnabled {
                SoundsControlCenter.shared.stop()
            }
        }) {
            ZStack {
                // 使用透明背景确保点击区域固定
                Color.clear.frame(width: size * 1.5, height: size * 1.5)
                
                Image(systemName: sharedData.soundSetting.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: size))
                    .animation(.linear(duration: 0.1), value: sharedData.soundSetting.isSoundEnabled)
            }
            .frame(width: size * 1.5, height: size * 1.5) // 强制固定 Frame 防止抖动
        }
    }
    
    // 辅助函数：创建统一风格的控制按钮
    func controlButton(iconName: String, rotated: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(rotated ? .degrees(90) : .degrees(0))
                .frame(width: 60, height: 60)
                .background(brightBlue)
                .clipShape(Circle())
        }
    }
}

#Preview {
    TimerPage()
}
