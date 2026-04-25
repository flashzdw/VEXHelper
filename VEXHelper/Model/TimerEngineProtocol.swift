//
//  TimerEngineProtocol.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/04/24.
//

import Foundation
import Combine

/// 统一的计时器引擎协议
protocol TimerEngineProtocol: ObservableObject {
    var status: TimerStatus { get }
    var timeRemaining: Int { get }
    var progress: Double { get }
    var timeString: String { get }
    
    func start()
    func pause()
    func stop()
    func reset()
    func perform(_ action: TimerControlAction)
}
