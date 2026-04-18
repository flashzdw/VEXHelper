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
    case remote
    case settings
}

struct ContentView: View {
    // 引用全局共享数据
    @StateObject var sharedData = SharedData.shared
    @AppStorage("appTheme") private var appTheme: String = "System"
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("launchMode") private var launchMode: LaunchMode = .modeSelection

    // 主导航状态
    @State private var selectedTab: AppTab = .timer
    @State private var isFullscreen: Bool = false
    @State private var hasSelectedMode: Bool = false
    @State private var hasInitializedLaunchMode: Bool = false

    // 使用 SharedData 中的 phoneTimerEngine
    private var phoneTimerEngine: PhoneTimerEngine {
        sharedData.phoneTimerEngine
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景层
            Color("AppDarkGray").ignoresSafeArea()

            if !hasSelectedMode {
                ModeSelectionView(sharedData: sharedData, hasSelectedMode: $hasSelectedMode)
                    .transition(.opacity)
                    .onChange(of: hasSelectedMode) { _, selected in
                        if selected {
                            if sharedData.activeTimerMode == .phone {
                                selectedTab = .timer
                            } else {
                                selectedTab = .remote
                            }
                        }
                    }
            } else {
                // 内容层 (使用 MainTabView)
                MainTabView(
                    sharedData: sharedData,
                    phoneTimerEngine: phoneTimerEngine,
                    isFullscreen: $isFullscreen,
                    selectedTab: $selectedTab,
                    shouldShowMenu: !isFullscreen,
                    hasSelectedMode: $hasSelectedMode
                )
                .transition(.opacity)
            }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
        .preferredColorScheme(colorScheme)
        .onAppear {
            if !hasInitializedLaunchMode {
                hasInitializedLaunchMode = true
                switch launchMode {
                case .modeSelection:
                    hasSelectedMode = false
                case .phoneTimer:
                    sharedData.switchToPhoneMode()
                    selectedTab = .timer
                    hasSelectedMode = true
                case .webTimer:
                    sharedData.switchToWebMode()
                    selectedTab = .remote
                    hasSelectedMode = true
                }
            }
            updateTabBarAppearance()
        }
        .onChange(of: appTheme) { _, _ in
            updateTabBarAppearance()
        }
        // 监听计时器状态
        .onReceive(phoneTimerEngine.$status) { status in
            timerStatus = status
        }
    }

    // 用于监听计时器状态
    @State private var timerStatus: TimerStatus = .idle
    
    /// 更新 TabBar 外观，确保在不同主题下颜色正确
    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // 设置磨砂效果
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // 设置背景色 (透明，以便显示磨砂)
        appearance.backgroundColor = UIColor.clear
        
        // 设置未选中项颜色 (灰色)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        // 设置选中项颜色 (系统蓝)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        // 应用到所有状态
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // 强制触发布局更新 (对于 SwiftUI 这是一个 hack，但有时候有效)
        // 通过切换 preferredColorScheme 已经能触发大部分更新
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
