//
//  ChatViewModel.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import SwiftUI
import Combine
import SwiftData
import CoreLocation

@Observable
class ChatViewModel {
    var modelContext: ModelContext
    var currentChat: ChatSummary
    
    init(modelContext: ModelContext, chat: ChatSummary) {
        self.modelContext = modelContext
        self.currentChat = chat
    }
    
    // MARK: - 统一发送入口
    /// 根据消息类型发送多媒体或文本
    func sendMessage(
        type: String = "text",
        text: String? = nil,
        time: String? = "",
        imageData: Data? = nil,
        videoData: Data? = nil,
        voiceData: Data? = nil,         // 新增
        voiceDuration: Double? = nil,   // 新增
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil
    ) {
        let now = Date()
        let timeString = formatTime(now)
        
        var videoPathName: String? = nil
        
        // --- 在存入数据库前，先处理缓存 ---
        if type == "video", let data = videoData {
            videoPathName = saveVideoToCache(data: data)
        }
        
        // 1. 创建消息实例
        let newMessage = Message(
            text: text ?? "",
            time: timeString,
            isFromMe: true,
            timestamp: now,
            messageType: type,
            imageData: imageData,
            videoData: videoData,
            voiceData: voiceData,
            voiceDuration: voiceDuration,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName
        )
        
        // 2. 建立关联（SwiftData 会自动处理插入）
        currentChat.messages?.append(newMessage)
        
        // 3. 更新会话摘要展示
        updateSummary(with: newMessage)
        
        // 4. 自动回复逻辑
        if type == "text" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.mockReply(to: text ?? "")
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.mockReply(to: "[\(type)]")
            }
        }
    }
    
    
    // MARK: - 私有辅助方法
    
    private func updateSummary(with message: Message) {
        let now = message.timestamp
        currentChat.lastTimestamp = now
        
        switch message.messageType {
        case "image":
            currentChat.lastMessage = "[图片]"
        case "location":
            currentChat.lastMessage = "[位置]"
        case "video":
            currentChat.lastMessage = "[视频]"
        case "voice":
            currentChat.lastMessage = "[语音]"
        default:
            currentChat.lastMessage = message.text
        }
        
        save()
    }

    private func mockReply(to userContent: String) {
        let now = Date()
        let replyText: String
        
        if userContent.contains("你好") {
            replyText = "你好呀！"
        } else if userContent == "[图片]" {
            replyText = "图片收到了，很赞！"
        } else if userContent == "[location]" {
            replyText = "看到你的位置了。"
        } else if userContent == "[video]" {
            replyText = "这么搞笑"
        }else if userContent == "[voice]" {
            replyText = "没听清"
        }
                    
        else {
            replyText = "收到消息。"
        }
        
        let replyMessage = Message(
            text: replyText,
            time: formatTime(now),
            isFromMe: false,
            timestamp: now
        )
        
        currentChat.messages?.append(replyMessage)
        currentChat.lastMessage = replyText
        currentChat.lastTimestamp = now
        currentChat.unreadCount += 1
        save()
    }
    
    private func save() {
        try? modelContext.save()
    }
    
    private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm"
         return formatter.string(from: date)
    }
    
    func saveVideoToCache(data: Data) -> String? {
        let fileName = "\(UUID().uuidString).mp4"
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachePath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName // 只存文件名，因为路径前半部分可能随 App 更新改变
        } catch {
            print("缓存视频失败: \(error)")
            return nil
        }
    }
}

