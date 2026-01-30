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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 计时器页面
            TimerPage(timerCenter: timerEngine, isFullscreen: $isFullscreen)
                .environmentObject(sharedData)
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(AppTab.timer)
            
            // 2. 设置页面
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .accentColor(.blue) // 选中颜色
        // 控制 TabBar 的背景材质
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        // 控制 TabBar 背景的显隐
        .toolbarBackground(shouldShowMenu ? .visible : .hidden, for: .tabBar)
        // 关键：控制 TabBar 本身的显隐
        .toolbar(shouldShowMenu ? .visible : .hidden, for: .tabBar)
        // 确保全屏时 TabBar 不占用空间
        .ignoresSafeArea(edges: isFullscreen ? .bottom : [])
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
