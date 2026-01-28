//
//  ContentView.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import SwiftUI

struct ContentView: View {
    // 引用全局共享数据
    @StateObject var sharedData = SharedData.shared
    
    // 控制视图显示的枚举或状态
    @State private var showTimerPage = false
    
    var body: some View {
        ZStack {
            if showTimerPage {
                TimerPage()
                    .transition(.opacity) // 淡入淡出效果
            } else {
                WelcomeView(startAction: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTimerPage = true
                    }
                })
                .transition(.opacity)
            }
        }
        .environmentObject(sharedData)
    }
}

// 简单的欢迎页面组件
struct WelcomeView: View {
    var startAction: () -> Void
    let darkGray = Color("darkGray")
    let brightBlue = Color.blue
    
    var body: some View {
        ZStack {
            darkGray.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundColor(brightBlue)
                
                Text("VEX Helper")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                Text("VEX 机器人竞赛辅助工具")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: startAction) {
                    Text("开始使用")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 15)
                        .background(brightBlue)
                        .cornerRadius(30)
                }
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    ContentView()
}
