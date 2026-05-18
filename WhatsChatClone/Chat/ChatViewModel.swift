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
//    var chatId: String // 记录当前是在跟谁聊
    var currentChat: ChatSummary // 直接持有会话对象
    
    init(modelContext: ModelContext, chat: ChatSummary) {
        self.modelContext = modelContext
        self.currentChat = chat
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
        currentChat.messages?.append(newMessage)
//        modelContext.insert(newMessage)
        
        // 同步更新首页摘要
        currentChat.lastMessage = text
        currentChat.lastTimestamp = now
        // 3. (可选) 强制保存
        save()
        
        // 延迟 1.5 秒回复，显得更真实
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.mockReply(to: text)
        }
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
        currentChat.messages?.append(newMessage)
//        modelContext.insert(newMessage)
        currentChat.lastMessage = "[图片]"
        currentChat.lastTimestamp = now
        save()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.mockReply(to: "图片")
        }
    }
    
    private func mockReply(to userText: String) {
        let now = Date()
        
        // 简单的回复逻辑
        let replyText: String
        if userText.contains("你好") {
            replyText = "你好呀！最近怎么样？"
        } else if userText.contains("图片") {
            replyText = "看到了，这张图很漂亮！"
        } else {
            replyText = "收到消息了：\"\(userText)\"。"
        }
        
        let replyMessage = Message(
            text: replyText,
            time: formatTime(now),
            isFromMe: false, // 关键：设置为对方发送
            timestamp: now
        )
        currentChat.messages?.append(replyMessage)
        currentChat.lastMessage = replyMessage.text
        currentChat.lastTimestamp = now
        currentChat.unreadCount += 1
        save()
    }
    
    private func save() {
        try? modelContext.save()
    }
    
    

    // 辅助函数：统一时间格式
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
