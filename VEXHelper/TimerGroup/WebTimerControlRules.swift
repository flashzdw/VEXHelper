import Foundation

enum WebTimerControlAction: Hashable {
    case start
    case pause
    case stop
    case resetCancel
    case reset
}

extension WebTimerControlAction {
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

enum WebTimerControlRules {
    static func actions(for status: TimerStatus) -> [WebTimerControlAction] {
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

extension WebTimerEngine {
    func perform(_ action: WebTimerControlAction) {
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
