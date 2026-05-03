//
//  SharedData.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import SwiftUI
import Combine

/// 计时器状态枚举
enum TimerStatus {
    case idle       // 空闲
    case running    // 运行中
    case paused     // 暂停
    case stopped    // 停止
}

/// 启动应用时打开的模式枚举
enum LaunchMode: String, CaseIterable, Identifiable {
    case phoneTimer
    case webTimer

    var id: String { self.rawValue }

    var localizedName: String {
        switch self {
        case .phoneTimer: return "Phone Timer"
        case .webTimer: return "Remote Control"
        }
    }
}

/// 计时模式枚举，用于区分手机计时和Web计时
enum TimerMode: String, CaseIterable, Identifiable {
    case phone   // 手机计时模式
    case web     // Web计时模式

    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .phone: return "Phone Timer"
        case .web: return "Remote Control"
        }
    }
}

/// 全局共享数据，用于管理应用级设置和状态
class SharedData: ObservableObject {
    static let shared = SharedData()

    // MARK: - Timer Engines

    /// 手机端计时器引擎
    @Published var phoneTimerEngine: PhoneTimerEngine

    /// Web端计时器引擎
    @Published var webTimerEngine: WebTimerEngine

    // MARK: - Remote Control Managers

    /// 手机端远程控制管理器
    @Published var phoneRemoteControlManager: PhoneRemoteControlManager

    /// Web端远程控制管理器
    @Published var webRemoteControlManager: WebRemoteControlManager

    // MARK: - Timer Mode

    /// 当前激活的计时模式
    @Published var activeTimerMode: TimerMode = .phone

    // MARK: - Settings

    /// 是否使用自定义计时器 (默认: 否)
    @Published var isPhoneCustomTimer: Bool {
        didSet { 
            UserDefaults.standard.set(isPhoneCustomTimer, forKey: "isPhoneCustomTimer") 
            phoneTimerEngine.updateIsCustom(isPhoneCustomTimer)
        }
    }

    @Published var isWebCustomTimer: Bool {
        didSet { 
            UserDefaults.standard.set(isWebCustomTimer, forKey: "isWebCustomTimer") 
            webTimerEngine.updateIsCustom(isWebCustomTimer)
        }
    }

    /// 手机端计时器比赛总时长 (秒)
    @Published var phoneTotalTime: Int {
        didSet { 
            UserDefaults.standard.set(phoneTotalTime, forKey: "phoneTotalTime") 
            phoneTimerEngine.updateTotalTime(phoneTotalTime)
        }
    }

    /// Web端计时器比赛总时长 (秒)
    @Published var webTotalTime: Int {
        didSet { 
            UserDefaults.standard.set(webTotalTime, forKey: "webTotalTime") 
            webTimerEngine.updateTotalTime(webTotalTime)
        }
    }

    /// 是否启用音效
    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "isSoundEnabled") }
    }

    /// 启动应用时打开的模式设置 (使用 UserDefaults 持久化)
    @AppStorage("launchMode") var launchMode: LaunchMode = .phoneTimer

    private init() {
        self.phoneTotalTime = UserDefaults.standard.object(forKey: "phoneTotalTime") as? Int ?? 60
        self.webTotalTime = UserDefaults.standard.object(forKey: "webTotalTime") as? Int ?? 60
        self.isPhoneCustomTimer = UserDefaults.standard.object(forKey: "isPhoneCustomTimer") as? Bool ?? false
        self.isWebCustomTimer = UserDefaults.standard.object(forKey: "isWebCustomTimer") as? Bool ?? false
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? true

        let phoneTimerEngine = PhoneTimerEngine()
        let webTimerEngine = WebTimerEngine()
        let networkService = LocalNetworkService.shared

        self.phoneTimerEngine = phoneTimerEngine
        self.webTimerEngine = webTimerEngine
        self.phoneRemoteControlManager = PhoneRemoteControlManager(timerEngine: phoneTimerEngine, networkService: networkService)
        self.webRemoteControlManager = WebRemoteControlManager(timerEngine: webTimerEngine, networkService: networkService)
        setupNetworkInitialStateSync()
    }

    // MARK: - Mode Switching

    /// 切换到Web计时模式
    func switchToWebMode() {
        // 停止手机计时
        phoneTimerEngine.reset()

        // 切换到Web模式
        activeTimerMode = .web
        syncBrowserMuteForActiveMode()
    }

    /// 切换到手机计时模式
    func switchToPhoneMode() {
        // 停止Web计时
        webTimerEngine.reset()

        // 切换到手机模式
        activeTimerMode = .phone
        syncBrowserMuteForActiveMode()
    }

    private func syncBrowserMuteForActiveMode() {
        let isMuted: Bool
        switch activeTimerMode {
        case .phone:
            // 手机模式下，强制 Web 端静音，确保其不发声
            isMuted = true
        case .web:
            isMuted = webRemoteControlManager.isMuted
        }
        LocalNetworkService.shared.broadcast(message: TimerMessageFactory.toggleMute(isMuted: isMuted))
    }

    private func setupNetworkInitialStateSync() {
        LocalNetworkService.shared.onNewConnection = { [weak self] connection in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.syncInitialState(to: connection)
            }
        }
    }

    private func syncInitialState(to connection: WebSocketConnection) {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        connection.send(string: TimerMessageFactory.language(lang: lang))

        let isMuted: Bool
        let snapshot: TimerSnapshot

        switch activeTimerMode {
        case .phone:
            // 彻底隔离：手机模式下不向 Web 同步任何真实数据
            isMuted = true // 强制静音，防止手机模式下网页发声
            snapshot = TimerSnapshot(timeRemaining: 0, timeString: "--:--", progress: 0.0, status: .idle)
        case .web:
            isMuted = webRemoteControlManager.isMuted
            snapshot = TimerSnapshot(
                timeRemaining: webTimerEngine.timeRemaining,
                timeString: webTimerEngine.timeString,
                progress: webTimerEngine.progress,
                status: webTimerEngine.status
            )
        }

        connection.send(string: TimerMessageFactory.toggleMute(isMuted: isMuted))
        connection.send(string: TimerMessageFactory.update(snapshot: snapshot))
    }
}

// MARK: - UserDefaults Extension

/// 扩展 UserDefaults 以支持 publisher
extension UserDefaults {
    @objc dynamic var appLanguage: String? {
        return string(forKey: "appLanguage")
    }
}
