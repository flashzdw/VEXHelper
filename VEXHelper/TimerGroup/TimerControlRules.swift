//
//  TimerControlRules.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/04/24.
//

import Foundation

enum TimerControlAction: Hashable {
    case start
    case pause
    case stop
    case resetCancel
    case reset
}

extension TimerControlAction {
    var iconName: String {
        switch self {
        case .start:
            return "play.fill"
        case .pause:
            return "pause.fill"
        case .stop:
            return "square.fill"
        case .resetCancel:
            return "xmark"
        case .reset:
            return "arrow.triangle.2.circlepath"
        }
    }
}

enum TimerControlRules {
    static func actions(for status: TimerStatus) -> [TimerControlAction] {
        switch status {
        case .idle:
            return [.start]
        case .running:
            return [.pause, .stop]
        case .paused:
            return [.resetCancel, .start]
        case .stopped:
            return [.reset]
        }
    }
}

extension TimerEngineProtocol {
    func perform(_ action: TimerControlAction) {
        switch action {
        case .start:
            start()
        case .pause:
            pause()
        case .stop:
            stop()
        case .resetCancel:
            reset()
        case .reset:
            reset()
        }
    }
}
