//
//  ContentView.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import SwiftUI

/// 定义 App 的主 Tab
enum AppTab {
    case timer
    case settings
}

struct ContentView: View {
    // 引用全局共享数据
    @StateObject var sharedData = SharedData.shared
    @AppStorage("appTheme") private var appTheme: String = "System"
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("menuVisibilityMode") private var menuVisibilityMode: MenuVisibilityMode = .duringCounting
    
    // 主导航状态
    @State private var selectedTab: AppTab = .timer
    @State private var isFullscreen: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景层
            Color("darkGray").ignoresSafeArea()
            
            // 内容层 (使用 MainTabView)
            MainTabView(
                sharedData: sharedData,
                timerEngine: timerEngine,
                isFullscreen: $isFullscreen,
                selectedTab: $selectedTab,
                shouldShowMenu: shouldShowMenu
            )
        }
        .environment(\.locale, Locale(identifier: appLanguage))
        .preferredColorScheme(colorScheme)
        // 监听计时器状态
        .onReceive(timerEngine.$status) { status in
            timerStatus = status
        }
    }
    
    // 用于监听计时器状态
    @StateObject private var timerEngine = TimerEngine()
    @State private var timerStatus: TimerStatus = .idle
    
    /// 计算菜单是否应该显示
    private var shouldShowMenu: Bool {
        // 全屏模式下始终隐藏
        if isFullscreen { return false }
        
        switch menuVisibilityMode {
        case .duringCounting:
            // 计时过程中隐藏（默认）
            return timerStatus != .running
            
        case .afterStart:
            // 开始计时后隐藏（直到重置）
            // 只要不是 idle 状态（即 running, paused, stopped）都隐藏
            return timerStatus == .idle
            
        case .alwaysShow:
            // 不隐藏
            return true
        }
    }
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil // System
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
