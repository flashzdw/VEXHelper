//
//  TimerPage.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/24.
//

import SwiftUI

struct TimerPage: View {
    @StateObject var timerCenter = TimerEngine()
    // 监听全局数据变化
    @ObservedObject var sharedData = SharedData.shared
    @Binding var isFullscreen: Bool
    
    let darkGray = Color("darkGray")
    let brightBlue = Color.blue
    
    // 部分圆角形状
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
                // 全屏模式
                fullScreenView
            } else {
                // 竖屏模式
                portraitView
            }
        }
        // 设置状态栏样式
        // .preferredColorScheme(.dark) // 由ContentView控制
    }
    
    // MARK: - Portrait View
    var portraitView: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // 顶部控制栏
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFullscreen = true
                        }
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(brightBlue)
                            .clipShape(Circle())
                    }
                    .padding(.top, 40)
                    .padding(.trailing, 20)
                }
                
                Spacer()
                
                // 倒计时圆环
                PortraitTimerView(timerEngine: timerCenter, sharedData: sharedData)
                
                Spacer()
                
                // 底部控制按钮
                HStack(spacing: 50) {
                    switch timerCenter.status {
                    case .idle:
                        // 初始状态：显示开始
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
                        controlButton(iconName: "xmark", action: {
                            timerCenter.reset()
                        })
                        controlButton(iconName: "play.fill", action: {
                            timerCenter.start()
                        })
                        
                    case .stopped:
                        // 停止/结束：显示重置
                        controlButton(iconName: "arrow.triangle.2.circlepath", action: {
                            timerCenter.reset()
                        })
                    }
                }
                .padding(.bottom, 120) // 增加底部边距，给悬浮菜单留空间
            }
        }
    }
    
    // MARK: - Fullscreen View
    var fullScreenView: some View {
        ZStack {
            LandscapeTimerView(timerEngine: timerCenter, sharedData: sharedData)
            
            // 退出全屏按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFullscreen = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.black.opacity(0.5))
                            .clipShape(CornerRadiusShape(radius: 35, corners: .bottomLeft))
                            .rotationEffect(.degrees(180))
                    }
                }
                .padding(.top, 28)
                .padding(.trailing, 28)
                
                Spacer()
            }
            .ignoresSafeArea()
            
            // 侧边控制按钮（对应竖屏的底部，旋转90度）
            HStack {
                VStack(spacing: 30) {
                    Spacer()
                    switch timerCenter.status {
                    case .idle:
                        controlButton(iconName: "play.fill", rotated: true, action: {
                            timerCenter.start()
                        })
                        
                    case .running:
                        controlButton(iconName: "pause.fill", rotated: true, action: {
                            timerCenter.pause()
                        })
                        controlButton(iconName: "square.fill", rotated: true, action: {
                            timerCenter.stop()
                        })
                        
                    case .paused:
                        controlButton(iconName: "xmark", rotated: true, action: {
                            timerCenter.reset()
                        })
                        controlButton(iconName: "play.fill", rotated: true, action: {
                            timerCenter.start()
                        })
                        
                    case .stopped:
                        controlButton(iconName: "arrow.triangle.2.circlepath", rotated: true, action: {
                            timerCenter.reset()
                        })
                    }
                    Spacer()
                }
                .padding(.leading, 40)
                
                Spacer()
            }
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

struct TimerPage_Previews: PreviewProvider {
    static var previews: some View {
        TimerPage(isFullscreen: .constant(false))
    }
}
