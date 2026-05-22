//
//  HapticManager.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/22.
//

import UIKit

struct HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    /// 触发撞击振动
    /// - Parameter style: .light(轻微, 适合滑块边界) / .medium(中等, 适合开始录音) / .heavy(沉重)
    func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare() // 提前准备，降低延迟
        generator.impactOccurred()
    }
}
