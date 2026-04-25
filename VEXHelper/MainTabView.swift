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

    @AppStorage("appTheme") private var appTheme: String = "System"

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                // 1. 核心操作区
                Group {
                    if sharedData.activeTimerMode == .phone {
                        TimerPage(timerCenter: sharedData.phoneTimerEngine, isFullscreen: $isFullscreen)
                            .environmentObject(sharedData)
                    } else {
                        TimerPage(timerCenter: sharedData.webTimerEngine, isFullscreen: $isFullscreen)
                            .environmentObject(sharedData)
                    }
                }
                .toolbar(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                .toolbarBackground(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .tabItem {
                    Label("Control", systemImage: "timer")
                }
                .tag(AppTab.timer)

                // 2. 远程连接页面
                RemoteServerView()
                    .toolbar(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                    .toolbarBackground(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                    .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                    .tabItem {
                        Label("Connection", systemImage: "network")
                    }
                    .tag(AppTab.remote)

                // 3. 设置页面
                SettingsView(timerEngine: phoneTimerEngine)
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
        }
        .onChange(of: LocalNetworkService.shared.connectedClientsCount) { oldValue, newValue in
            if sharedData.activeTimerMode == .web && oldValue == 0 && newValue > 0 {
                // 当有新客户端连接时，自动切换到控制面板 Tab
                withAnimation {
                    selectedTab = .timer
                }
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
                shouldShowMenu: true
            )
        }
    }
}
