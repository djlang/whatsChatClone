//
//  ChatViewModel.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import SwiftUI
import Combine
import SwiftData


@Observable // 使用 iOS 17 的新观察模式
class ChatViewModel {

    
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    

    
    func sendMessage(_ text: String) {
        // 1. 获取当前精确时间戳和格式化后的字符串
        let now = Date()
        let timeString = formatTime(now)
        
        // 2. 创建并插入消息（确保传入 timestamp）
        let newMessage = Message(
            text: text,
            time: timeString,
            isFromMe: true,
            timestamp: now // 关键：确保精确排序
        )
        
        modelContext.insert(newMessage)
        
        // 3. (可选) 强制保存
        try? modelContext.save()
    }

    func sendImageMessage(imageData: Data) {
        let now = Date()
        let timeString = formatTime(now)
        
        let newMessage = Message(
            text: "[图片]",
            time: timeString,
            isFromMe: true,
            imageData: imageData,
            timestamp: now // 关键：确保图片消息也在正确位置
        )
        
        modelContext.insert(newMessage)
        try? modelContext.save()
    }

    // 辅助函数：统一时间格式
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
