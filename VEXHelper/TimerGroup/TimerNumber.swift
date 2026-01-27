//
//  TimerNumber.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/24.
//

import SwiftUI

struct TimerNumber: View {
    let timeString: String
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 80, weight: .bold, design: .default))
            .foregroundColor(.white)
            // 使用等宽字体数字，避免倒计时跳动
            .monospacedDigit()
    }
}

#Preview {
    ZStack {
        Color.gray
        TimerNumber(timeString: "1:00")
    }
}
