//
//  HorizontalTimerNumber.swift
//  VEXHelper
//
//  Created by VEXHelper Dev on 2026/1/24.
//

import SwiftUI

struct HorizontalTimerNumber: View {
    let timeString: String
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 150, weight: .bold, design: .default)) // 更大的字体
            .foregroundColor(.white)
            .monospacedDigit()
            .rotationEffect(.degrees(90)) // 旋转90度
            .fixedSize() // 确保旋转后布局正确
    }
}

#Preview {
    ZStack {
        Color.gray.edgesIgnoringSafeArea(.all)
        HorizontalTimerNumber(timeString: "1:00")
    }
}
