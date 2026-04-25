import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var currentPage = 0
    
    var isZh: Bool {
        return appLanguage == "zh-Hans"
    }
    
    var body: some View {
        ZStack {
            Color("AppDarkGray").ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // 第 0 页：选择语言
                VStack(spacing: 40) {
                    Spacer()
                    Image(systemName: "globe")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(isZh ? "选择语言" : "Select Language")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            appLanguage = "zh-Hans"
                        }) {
                            Text(verbatim: "中文")
                                .font(.headline)
                                .foregroundColor(appLanguage == "zh-Hans" ? .white : .blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(appLanguage == "zh-Hans" ? Color.blue : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            appLanguage = "en"
                        }) {
                            Text(verbatim: "English")
                                .font(.headline)
                                .foregroundColor(appLanguage == "en" ? .white : .blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(appLanguage == "en" ? Color.blue : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    // 占位，保持布局一致，留出指示器位置
                    Spacer().frame(height: 80)
                }
                .tag(0)
                
                // 第 1 页：双模式介绍
                VStack(spacing: 40) {
                    Spacer()
                    
                    Text(isZh ? "双模式计时" : "Dual-Mode Timer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 30) {
                        // 手机模式介绍
                        HStack(spacing: 20) {
                            Image(systemName: "iphone")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                                .frame(width: 60)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(isZh ? "手机模式" : "Phone Mode")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(isZh ? "随时随地独立计时" : "Independent timer on the go")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        
                        // 网页模式介绍
                        HStack(spacing: 20) {
                            Image(systemName: "desktopcomputer")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                                .frame(width: 60)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(isZh ? "网页模式" : "Web Mode")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(isZh ? "连接大屏幕，由手机控制显示" : "Connect to a large screen, controlled by your phone")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                    Spacer().frame(height: 80)
                }
                .tag(1)
                
                // 第 2 页：欢迎页
                OnboardingPageView(
                    iconName: "hand.wave.fill",
                    title: isZh ? "欢迎使用 VEXHelper" : "Welcome to VEXHelper",
                    description: isZh ? "您的专属 VEX 机器人比赛助手，助您轻松掌控每一场比赛。" : "Your exclusive VEX Robotics competition assistant, helping you easily master every match.",
                    showStartButton: true,
                    startButtonTitle: isZh ? "开始使用" : "Start",
                    startAction: {
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

struct OnboardingPageView: View {
    let iconName: String
    let title: String
    let description: String
    var showStartButton: Bool = false
    var startButtonTitle: String = "开始使用"
    var startAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: iconName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            if showStartButton {
                Button(action: {
                    startAction?()
                }) {
                    Text(startButtonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            } else {
                // 占位，保持布局一致，留出指示器位置
                Spacer()
                    .frame(height: 80)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
