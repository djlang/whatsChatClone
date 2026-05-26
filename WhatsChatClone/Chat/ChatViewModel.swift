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
import Photos
import AVFoundation

@Observable
class ChatViewModel {
    var modelContext: ModelContext
    var currentChat: ChatSummary
    
    init(modelContext: ModelContext, chat: ChatSummary) {
        self.modelContext = modelContext
        self.currentChat = chat
    }
    
    // MARK: - 视频处理逻辑
    /// 处理视频选择、请求资产并压缩发送
    func handleVideoSelection(asset: PHAsset, thumbnailData: Data) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, _) in
            guard let urlAsset = avAsset as? AVURLAsset else { return }
            let videoURL = urlAsset.url
            
            MediaService.shared.compressVideo(inputURL: videoURL) { compressedData in
                guard let data = compressedData else { return }
                DispatchQueue.main.async {
                    self.sendMessage(type: "video", imageData: thumbnailData, videoData: data)
                }
            }
        }
    }
    
    // MARK: - 位置处理逻辑
    /// 处理位置消息，逆地理编码并发送
    func sendLocationMessage(_ loc: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) { placemarks, error in
            let address = placemarks?.first?.name ?? "未知地点"
            DispatchQueue.main.async {
                self.sendMessage(type: "location", text: nil, imageData: nil, latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, locationName: address)
            }
        }
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
        
        let isMedia = (type != "text")
        
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
        
        newMessage.isSending = isMedia // 如果是多媒体，上屏先转圈
        
        // 2. 建立关联（SwiftData 会自动处理插入）
        currentChat.messages?.append(newMessage)
        
        // 3. 更新会话摘要展示
        updateSummary(with: newMessage)
        
        // . 延迟逻辑流：模拟网络不佳/后台处理
        if isMedia {
            // 🎬 模拟 1.5 秒的网络传输耗时
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    newMessage.isSending = false // 发送成功，菊花消失
                }
                self.save()
                
                // 收到消息后，隔 1.5 秒对方开始输入并模拟回复
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    let mockContent = type == "location" ? "[location]" : "[\(type)]"
                    self.mockReply(to: mockContent)
                }
            }
        } else {
            // 📝 文本消息维持原状：瞬间发送，1.5秒后对方回复
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.mockReply(to: text ?? "")
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
    
    
    
    /// 插入一条音视频通话历史记录
    func sendCallMessage(type: String, duration: TimeInterval) {
        let now = Date()
        let timeString = formatTime(now)
        
        // 1. 创建特殊通话消息模型（假设你已经扩展了字段）
        let callMessage = Message(
            text: type == "audio" ? "语音通话" : "视频通话",
            time: timeString,
            isFromMe: true,
            timestamp: now,
            messageType: type == "audio" ? "call_audio" : "call_video"
        )
        // 存储时长（秒）
        callMessage.voiceDuration = duration // 借用或使用专用的 callDuration 字段
        
        // 2. 关联并持久化
        currentChat.messages?.append(callMessage)
        
        // 3. 更新会话摘要显示
        currentChat.lastMessage = type == "audio" ? "[语音通话]" : "[视频通话]"
        currentChat.lastTimestamp = now
        
        save()
    }
}

