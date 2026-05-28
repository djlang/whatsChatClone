//
//  Color+extension.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    // MARK: - WhatsApp Adaptive Colors
    
    static var waBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark 
                ? UIColor(red: 0.04, green: 0.08, blue: 0.10, alpha: 1.0) // 深蓝黑
                : UIColor(red: 0.94, green: 0.91, blue: 0.88, alpha: 1.0) // 浅米黄
        })
    }
    
    static var waMyBubble: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.00, green: 0.36, blue: 0.29, alpha: 1.0) // 深绿色
                : UIColor(red: 0.00, green: 0.53, blue: 0.43, alpha: 1.0) // 经典绿
        })
    }
    
    static var waOtherBubble: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.13, green: 0.17, blue: 0.20, alpha: 1.0) // 深灰色
                : .white
        })
    }
    
    static var waInputBarBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.13, green: 0.17, blue: 0.20, alpha: 1.0)
                : UIColor.systemGroupedBackground
        })
    }
    
    static var waInputBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.15, green: 0.20, blue: 0.25, alpha: 1.0)
                : .white
        })
    }
}


