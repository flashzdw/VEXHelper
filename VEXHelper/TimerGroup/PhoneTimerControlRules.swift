import Foundation

enum PhoneTimerControlAction: Hashable {
    case start
    case pause
    case stop
    case resetCancel
    case reset
}

extension PhoneTimerControlAction {
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

enum PhoneTimerControlRules {
    static func actions(for status: TimerStatus) -> [PhoneTimerControlAction] {
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

extension PhoneTimerEngine {
    func perform(_ action: PhoneTimerControlAction) {
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
