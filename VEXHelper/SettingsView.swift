//
//  SettingsView.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/28.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerEngine: TimerEngine
    
    @AppStorage("appTheme") private var appTheme: String = "System"
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("menuVisibilityMode") private var menuVisibilityMode: MenuVisibilityMode = .afterStart
    @AppStorage("showRemoteTab") private var showRemoteTab: Bool = false
    
    // 使用与 TimerPage 相同的背景色
    private let darkGray = Color("darkGray")
    
    init(timerEngine: TimerEngine) {
        self.timerEngine = timerEngine
        // 配置 Form 的背景为透明，以便显示底层的 darkGray
        UITableView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 统一的深色背景
                darkGray.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 标题栏
                    HStack {
                        Text("Settings")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 10)
                    .zIndex(1) // 确保标题在最上层
                    
                    ZStack(alignment: .top) {
                        // 标准 Form 组件
                        Form {
                            Section {
                                Toggle("Show Remote Control Tab", isOn: $showRemoteTab)
                            } header: {
                                Text("Display")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Section {
                                Picker(selection: $appTheme, label: Text("Theme")) {
                                    Text("System").tag("System")
                                    Text("Light").tag("Light")
                                    Text("Dark").tag("Dark")
                                }
                            } header: {
                                Text("Theme")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Section {
                                Picker(selection: $menuVisibilityMode, label: Text("Menu Visibility")) {
                                    ForEach(MenuVisibilityMode.allCases) { mode in
                                        Text(LocalizedStringKey(mode.localizedName)).tag(mode)
                                    }
                                }
                            } header: {
                                Text("Menu Visibility")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Section {
                                Picker(selection: $appLanguage, label: Text("Language")) {
                                    Text(verbatim: "English").tag("en")
                                    Text(verbatim: "中文").tag("zh-Hans")
                                }
                            } header: {
                                Text("Language")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .scrollContentBackground(.hidden) // 隐藏 Form 默认背景
                        .padding(.top, 40) // 增加顶部内边距，避开虚化遮罩
                        
                        // 顶部渐变虚化遮罩
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        darkGray,
                                        darkGray.opacity(0.8),
                                        darkGray.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 60)
                            .allowsHitTesting(false) // 允许点击穿透
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(timerEngine: TimerEngine())
    }
}
