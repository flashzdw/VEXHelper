//
//  MainTabView.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/30.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var sharedData: SharedData
    @ObservedObject var phoneTimerEngine: PhoneTimerEngine
    @Binding var isFullscreen: Bool
    @Binding var selectedTab: AppTab

    // 从父视图传递过来的菜单显示状态
    let shouldShowMenu: Bool
    @Binding var hasSelectedMode: Bool

    @AppStorage("appTheme") private var appTheme: String = "System"
    @AppStorage("showRemoteTab") private var showRemoteTab: Bool = false

    var canGoBack: Bool {
        if sharedData.activeTimerMode == .phone {
            return sharedData.phoneTimerEngine.status == .idle
        } else {
            return sharedData.webTimerEngine.status == .idle
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $selectedTab) {
                // 1. 计时器页面（仅在手机计时模式下显示）
                if sharedData.activeTimerMode == .phone {
                    TimerPage(timerCenter: phoneTimerEngine, isFullscreen: $isFullscreen)
                        .environmentObject(sharedData)
                        // 将 Toolbar 控制移到子视图内部
                        .toolbar(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                        .toolbarBackground(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                        .tabItem {
                            Label("Timer", systemImage: "timer")
                        }
                        .tag(AppTab.timer)
                }

                // 2. 远程控制页面（Web计时模式下显示）
                if sharedData.activeTimerMode == .web {
                    RemoteServerView()
                        .toolbar(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                        .toolbarBackground(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                        .tabItem {
                            Label("Remote Control", systemImage: "network")
                        }
                        .tag(AppTab.remote)
                }

                // 3. 设置页面
                SettingsView(timerEngine: phoneTimerEngine)
                    // 设置页面也应用同样的隐藏逻辑
                    .toolbar(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                    .toolbarBackground(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                    .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(AppTab.settings)
            }
            .accentColor(.blue) // 选中颜色
            // 启用 TabBar 显隐动画
            .animation(.easeInOut(duration: 0.3), value: shouldShowMenu)
            // 确保全屏时 TabBar 不占用空间
            .ignoresSafeArea(edges: isFullscreen ? .bottom : [])
            
            // 返回模式选择的全局按钮
            if canGoBack && !isFullscreen {
                Button(action: {
                    withAnimation(.easeInOut) {
                        hasSelectedMode = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("模式选择")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
                .padding(.leading, 16)
                .padding(.top, 10) // 紧贴安全区域顶部
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MainTabView(
                sharedData: SharedData.shared,
                phoneTimerEngine: SharedData.shared.phoneTimerEngine,
                isFullscreen: .constant(false),
                selectedTab: .constant(.timer),
                shouldShowMenu: true,
                hasSelectedMode: .constant(true)
            )
        }
    }
}
