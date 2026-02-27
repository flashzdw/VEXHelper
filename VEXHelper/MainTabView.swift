//
//  MainTabView.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/30.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var sharedData: SharedData
    @ObservedObject var timerEngine: TimerEngine
    @Binding var isFullscreen: Bool
    @Binding var selectedTab: AppTab
    
    // 从父视图传递过来的菜单显示状态
    let shouldShowMenu: Bool
    
    @AppStorage("appTheme") private var appTheme: String = "System"
    @AppStorage("showRemoteTab") private var showRemoteTab: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 计时器页面
            TimerPage(timerCenter: timerEngine, isFullscreen: $isFullscreen)
                .environmentObject(sharedData)
                // 将 Toolbar 控制移到子视图内部
                .toolbar(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                .toolbarBackground(shouldShowMenu ? .visible : .hidden, for: .tabBar)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(AppTab.timer)
            
            // 2. 远程控制页面
            if showRemoteTab {
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
            SettingsView(timerEngine: timerEngine)
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
        // 禁用 TabBar 显隐动画
        .animation(nil, value: shouldShowMenu)
        // 确保全屏时 TabBar 不占用空间
        .ignoresSafeArea(edges: isFullscreen ? .bottom : [])
        // 当主题改变时，强制刷新 TabView
        .id(appTheme)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MainTabView(
                sharedData: SharedData.shared,
                timerEngine: TimerEngine(),
                isFullscreen: .constant(false),
                selectedTab: .constant(.timer),
                shouldShowMenu: true
            )
        }
    }
}
