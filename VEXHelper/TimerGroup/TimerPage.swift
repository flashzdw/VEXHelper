//
//  TimerPage.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/24.
//

import SwiftUI
import UIKit

struct TimerPage<Engine: TimerEngineProtocol>: View {
    @ObservedObject var timerCenter: Engine
    // 监听全局数据变化
    @ObservedObject var sharedData = SharedData.shared
    @Binding var isFullscreen: Bool
    
    let darkGray = Color("AppDarkGray")
    let brightBlue = Color.blue
    
    // 增加一个 State 用于控制弹窗
    @State private var showConnectionAlert = false
    
    // 部分圆角形状
    struct CornerRadiusShape: Shape {
        var radius: CGFloat = .infinity
        var corners: UIRectCorner = .allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }
    
    // 自适应圆角：取屏幕短边的 12.5% 以适配各类机型的物理圆角
    private var adaptiveCornerRadius: CGFloat {
        min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.125
    }

    var body: some View {
        ZStack {
            // 背景色
            darkGray.ignoresSafeArea()
            
            if isFullscreen {
                // 全屏模式
                fullScreenView
            } else {
                // 竖屏模式
                portraitView
            }
        }
        .alert(isPresented: $showConnectionAlert) {
            Alert(
                title: Text("No Connection"),
                message: Text("There are no connected clients. Please go to the Connection tab to connect a web client first."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: isFullscreen) { newValue in
            if newValue {
                AppDelegate.orientationLock = .landscape
                if #available(iOS 16.0, *) {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape))
                    }
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                }
                UIViewController.attemptRotationToDeviceOrientation()
            } else {
                AppDelegate.orientationLock = .portrait
                if #available(iOS 16.0, *) {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait))
                    }
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                }
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
    
    // MARK: - Portrait View
    var portraitView: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // 顶部控制栏
                HStack {
                    // 左上角：模式切换按钮
                    Button(action: {
                        toggleTimerMode()
                    }) {
                        HStack {
                            Image(systemName: sharedData.activeTimerMode == .phone ? "iphone" : "network")
                            Text(sharedData.activeTimerMode == .phone ? LocalizedStringKey("Phone") : LocalizedStringKey("Remote"))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(sharedData.activeTimerMode == .phone ? .white : .green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 10)
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    if sharedData.activeTimerMode == .phone {
                        // 右上角：全屏按钮 (仅手机计时模式显示)
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
                        .padding(.top, 10) // 与全局返回按钮对齐
                        .padding(.trailing, 20)
                    }
                }
                
                Spacer()
                
                // 倒计时圆环
                PortraitTimerView(timerEngine: timerCenter, sharedData: sharedData)
                
                Spacer()
                
                // 底部控制按钮
                HStack(spacing: 50) {
                    ForEach(TimerControlRules.actions(for: timerCenter.status), id: \.self) { action in
                        controlButton(iconName: action.iconName, action: {
                            timerCenter.perform(action)
                        })
                    }
                }
                .padding(.bottom, 120) // 增加底部边距，给悬浮菜单留空间
            }
        }
        .ignoresSafeArea(edges: .bottom) // 防止 TabBar 隐藏时布局跳动
    }
    
    // MARK: - Fullscreen View
    var fullScreenView: some View {
        ZStack {
            LandscapeTimerView(timerEngine: timerCenter, sharedData: sharedData)
            
            // 退出全屏按钮 (左上角)
            VStack {
                HStack {
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
                            .clipShape(CornerRadiusShape(radius: adaptiveCornerRadius, corners: [.topLeft, .bottomRight]))
                    }
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()
            
            // 底部控制按钮 (水平居中)
            VStack {
                Spacer()
                HStack(spacing: 50) {
                    ForEach(TimerControlRules.actions(for: timerCenter.status), id: \.self) { action in
                        controlButton(iconName: action.iconName, action: {
                            timerCenter.perform(action)
                        })
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    // 辅助函数：创建统一风格的控制按钮
    func controlButton(iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(brightBlue)
                .clipShape(Circle())
        }
    }
    
    // 切换计时模式逻辑
    private func toggleTimerMode() {
        if sharedData.activeTimerMode == .phone {
            // 试图切换到远程模式
            if LocalNetworkService.shared.connectedClientsCount > 0 {
                withAnimation {
                    sharedData.switchToWebMode()
                }
            } else {
                // 没有连接的客户端，提示用户
                showConnectionAlert = true
            }
        } else {
            // 切换回手机模式
            withAnimation {
                sharedData.switchToPhoneMode()
            }
        }
    }
}

struct TimerPage_Previews: PreviewProvider {
    static var previews: some View {
        TimerPage(timerCenter: SharedData.shared.phoneTimerEngine, isFullscreen: .constant(false))
    }
}
