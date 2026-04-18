//
//  Menu.swift
//  VEXHelper2
//
//  Created by DongZi.8009 on 2025/9/21.
//

import SwiftUI

struct Menu: View {
    @State private var selectedTab: TabItem = .timer
    @StateObject private var dataService = DataService()
    @StateObject private var gameTypeManager = GameTypeManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Timer Tab
            TimerView()
                .tabItem {
                    Image(systemName: TabItem.timer.icon)
                    Text(TabItem.timer.title)
                }
                .tag(TabItem.timer)
            
            // Scoreboard Tab
            ScoreboardView()
                .tabItem {
                    Image(systemName: TabItem.scoreboard.icon)
                    Text(TabItem.scoreboard.title)
                }
                .tag(TabItem.scoreboard)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Image(systemName: TabItem.history.icon)
                    Text(TabItem.history.title)
                }
                .tag(TabItem.history)
            
            // Teams Tab
            TeamsView()
                .tabItem {
                    Image(systemName: TabItem.teams.icon)
                    Text(TabItem.teams.title)
                }
                .tag(TabItem.teams)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: TabItem.settings.icon)
                    Text(TabItem.settings.title)
                }
                .tag(TabItem.settings)
        }
        .accentColor(.vexAccent)
        .environmentObject(dataService)
        .environmentObject(gameTypeManager)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        // 使用iOS16+的现代TabBar外观
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // 使用iOS26的材质背景
        appearance.backgroundColor = UIColor.systemBackground
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        
        // 现代化的选中状态样式
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.vexAccent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.vexAccent),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // 现代化的未选中状态样式
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // 使用iOS16+的分割线样式
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.3)
        appearance.shadowImage = nil
        
        // 应用现代外观
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // iOS16+的额外配置
        if #available(iOS 16.0, *) {
            UITabBar.appearance().isTranslucent = true
        }
    }
    
}

// MARK: - Tab Item Enum
// TabItem enum is now defined in Models/TabItem.swift

#Preview {
    Menu()
}