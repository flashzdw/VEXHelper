//
//  WebControlView.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/02/01.
//

import SwiftUI

/// 专用的 Web 端控制器界面
struct WebControlView: View {
    @ObservedObject var timerEngine: TimerEngine
    @ObservedObject var manager: RemoteControlManager // Add manager
    @Environment(\.presentationMode) var presentationMode
    
    // 复用 TimerPage 的颜色
    let darkGray = Color("darkGray")
    let brightBlue = Color.blue
    
    var body: some View {
        ZStack {
            darkGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44) // 固定 Frame
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(LocalizedStringKey("Web Controller"))
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    
                    // Mute Button
                    Button(action: {
                        manager.toggleMute()
                    }) {
                        Image(systemName: manager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44) // 固定 Frame
                            .background(manager.isMuted ? Color.red : Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // 时间显示 (大字)
                Text(timerEngine.timeString)
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
                
                // 控制按钮组
                HStack(spacing: 50) {
                    switch timerEngine.status {
                    case .idle:
                        controlButton(iconName: "play.fill", action: {
                            timerEngine.start()
                        })
                        
                    case .running:
                        controlButton(iconName: "pause.fill", action: {
                            timerEngine.pause()
                        })
                        controlButton(iconName: "square.fill", action: {
                            timerEngine.stop()
                        })
                        
                    case .paused:
                        controlButton(iconName: "xmark", action: {
                            timerEngine.reset()
                        })
                        controlButton(iconName: "play.fill", action: {
                            timerEngine.start()
                        })
                        
                    case .stopped:
                        controlButton(iconName: "arrow.triangle.2.circlepath", action: {
                            timerEngine.reset()
                        })
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarHidden(true)
    }
    
    // 辅助函数：创建统一风格的控制按钮
    func controlButton(iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(brightBlue)
                .clipShape(Circle())
                .shadow(color: brightBlue.opacity(0.4), radius: 10, x: 0, y: 5)
        }
    }
}
