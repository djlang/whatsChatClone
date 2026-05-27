//
//  Message.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/13.
//

import SwiftData
import Foundation


@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var text: String
    var time: String?
    var isFromMe: Bool
    var timestamp: Date      // 核心：用于物理排序，精确到毫秒
    var messageType: String = "text" // "text", "image",location, "audio", "video"

    @Attribute(.externalStorage) var imageData: Data? // 大数据（图片）建议开启外部存储优化
    
    ///视频消息
    @Attribute(.externalStorage) var videoData: Data?
    var videoPath: String? // 存储在 Caches 目录下的相对路径
    
    ///语音消息
    @Attribute(.externalStorage) var voiceData: Data? // 语音二进制数据
    var voiceDuration: Double? // 语音时长（秒）
    
    // 位置相关字段
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    
    // 群聊专属字段（单聊时可以为 nil）
    var senderName: String?
    var senderAvatar: String?
    
    
    var isSending: Bool = false // <-- 标示这条消息是否还在异步处理/发送中
    
    // 关键：建立反向关联
    var chatSummary: ChatSummary?
    
    init(
        text: String,
        time: String? = nil,
        isFromMe: Bool,
        timestamp: Date = Date(),
        messageType: String = "text",
        imageData: Data? = nil,
        videoData: Data? = nil,
        voiceData: Data? = nil,
        voiceDuration: Double? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        senderName: String? = nil,
        senderAvatar: String? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.time = time
        self.isFromMe = isFromMe
        self.timestamp = timestamp
        self.messageType = messageType
        self.imageData = imageData
        self.videoData = videoData
        self.voiceData = voiceData
        self.voiceDuration = voiceDuration
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.senderName = senderName
        self.senderAvatar = senderAvatar
        
    }
}

extension Message {
    /// 用于在会话列表预览中显示的文字内容
    var previewText: String {
        switch messageType {
        case "image":
            return "[图片]"
        case "location":
            return "[位置]"
        case "voice": // 预留给未来的语音功能
            return "[语音]"
        case "video":
            return "[视频]"
        default:
            return text
        }
    }
}

