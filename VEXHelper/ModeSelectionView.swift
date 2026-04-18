//
//  ModeSelectionView.swift
//  VEXHelper
//
//  Created by AI on 2026/04/18.
//

import SwiftUI

/// 启动时的模式选择界面
struct ModeSelectionView: View {
    @ObservedObject var sharedData: SharedData
    @Binding var hasSelectedMode: Bool
    
    let darkGray = Color("AppDarkGray")
    
    var body: some View {
        ZStack {
            darkGray.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Select Timer Mode")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                Spacer()
                
                // 手机计时按钮
                ModeButton(
                    title: "Phone Timer",
                    subtitle: "Timer and control on the phone screen",
                    icon: "iphone",
                    action: {
                        sharedData.switchToPhoneMode()
                        withAnimation(.easeInOut) {
                            hasSelectedMode = true
                        }
                    }
                )
                
                // Web计时按钮
                ModeButton(
                    title: "Remote Control",
                    subtitle: "Control with your phone, display on any browser",
                    icon: "network",
                    action: {
                        sharedData.switchToWebMode()
                        withAnimation(.easeInOut) {
                            hasSelectedMode = true
                        }
                    }
                )
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

/// 模式选择按钮组件
struct ModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(title))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(LocalizedStringKey(subtitle))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(24)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModeSelectionView(sharedData: SharedData.shared, hasSelectedMode: .constant(false))
    }
}
