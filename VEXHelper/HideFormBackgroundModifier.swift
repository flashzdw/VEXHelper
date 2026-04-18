//
//  HideFormBackgroundModifier.swift
//  VEXHelper
//
//  Created by AI on 2026/04/18.
//

import SwiftUI

struct HideFormBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content.onAppear {
                UITableView.appearance().backgroundColor = .clear
            }
        }
    }
}