//
//  ContentView.swift
//  VEXHelper
//
//  Created by DongZi.8009 on 2026/1/24.
//

import SwiftUI

struct ContentView: View {
    // 引用全局共享数据
    @StateObject var sharedData = SharedData.shared
    
    var body: some View {
        TimerPage()
            .environmentObject(sharedData)
    }
}



#Preview {
    ContentView()
}
