//
//  Date+extension.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/18.
//

import Foundation

extension Date {
    var chatListTimeStr: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            // 今天的消息，显示 时:分
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            // 昨天的消息，显示 昨天
            return "昨天"
        } else {
            // 更早的消息，显示 月-日 (如果是跨年消息，可以再加上年份)
            let formatter = DateFormatter()
            if calendar.component(.year, from: self) == calendar.component(.year, from: Date()) {
                formatter.dateFormat = "M月d日" // 同一年内，显示 "5月14日"
            } else {
                formatter.dateFormat = "yyyy/MM/dd" // 跨年显示 "2025/12/30"
            }
            return formatter.string(from: self)
        }
    }
}
