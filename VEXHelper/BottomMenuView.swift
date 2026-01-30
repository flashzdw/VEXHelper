//
//  BottomMenuView.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/28.
//

import SwiftUI

/// 定义 App 的主 Tab
enum AppTab {
    case timer
    case settings
}

struct BottomMenuView: View {
    @Binding var selectedTab: AppTab
    @Namespace private var animationNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            // Timer Tab
            tabButton(
                tab: .timer,
                title: NSLocalizedString("Timer", comment: "Timer tab"),
                icon: "timer",
                selectedIcon: "timer"
            )
            
            // Settings Tab
            tabButton(
                tab: .settings,
                title: NSLocalizedString("Settings", comment: "Settings tab"),
                icon: "gearshape",
                selectedIcon: "gearshape.fill"
            )
        }
        .padding(6) // 稍微增加内边距，让液态光标有呼吸空间
        .background {
            // 胶囊背景容器
            ZStack {
                // 1. 基础磨砂层
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // 2. 液态光标 (滑动背景)
                // 通过 matchedGeometryEffect 实现平滑滑动
                // 这里的几何信息需要从 Tab 按钮中获取
            }
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            // 玻璃边缘高光
            .overlay(
                Capsule(style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Tab Button Component
    @ViewBuilder
    private func tabButton(tab: AppTab, title: String, icon: String, selectedIcon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.4)) {
                selectedTab = tab
            }
            // 触觉反馈
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedTab == tab ? selectedIcon : icon)
                    .font(.system(size: 22, weight: .semibold))
                    .symbolEffect(.bounce, value: selectedTab == tab) // 恢复符号动画
                
                if selectedTab == tab {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize() // 防止文字截断
                        .transition(.move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity) // 均匀分布
            .contentShape(Rectangle()) // 扩大点击区域
            .foregroundColor(selectedTab == tab ? .white : .secondary)
            .background {
                if selectedTab == tab {
                    // 液态光标
                    ZStack {
                        // 1. 主体高亮层 (液态混合)
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.8),
                                        Color.blue.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 2. 内部流动光泽 (模拟液体反光)
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.2),
                                        .clear,
                                        .clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .padding(2)
                    }
                    .matchedGeometryEffect(id: "LiquidCursor", in: animationNamespace)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
}

struct BottomMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                BottomMenuView(selectedTab: .constant(.timer))
            }
        }
        .preferredColorScheme(.dark)
    }
}
