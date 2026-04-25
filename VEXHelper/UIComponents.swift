//
//  UIComponents.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/04/24.
//

import SwiftUI

/// 毛玻璃卡片组件，用于在暗色背景上展示层级信息
struct GlassCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

/// 状态指示灯
enum ConnectionStatus {
    case disconnected
    case waiting
    case connected
    
    var color: Color {
        switch self {
        case .disconnected: return .red
        case .waiting: return .yellow
        case .connected: return .green
        }
    }
}

struct StatusDotView: View {
    let status: ConnectionStatus
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: 10, height: 10)
            .shadow(color: status.color.opacity(0.6), radius: isAnimating ? 4 : 2)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .onAppear {
                if status == .connected || status == .waiting {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            }
            .onChange(of: status) { _, newStatus in
                if newStatus == .connected || newStatus == .waiting {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                } else {
                    withAnimation {
                        isAnimating = false
                    }
                }
            }
    }
}

/// 顶部 Toast 提示条
struct ToastBannerView: View {
    let message: String
    let systemImage: String
    let isError: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(isError ? .red : .green)
            
            Text(LocalizedStringKey(message))
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(radius: 10)
        .padding(.horizontal, 20)
    }
}
