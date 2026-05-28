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
    
    // MARK: - UI 交互状态 (从 View 下沉到 ViewModel)
    var inputText: String = ""
    var isVoiceMode: Bool = false
    var isRecordingVoice: Bool = false
    var isRecordingCancelled: Bool = false
    var voiceAudioLevel: Float = 0
    
    // 标记用户当前是否正停留在该聊天详情页内
    var isViewingChat: Bool = false
    
    // 状态模拟判定：名字包含“群”、“交流”、“沙龙”等关键字即为群聊
    private var isGroupChat: Bool {
        currentChat.name.contains("群") || currentChat.name.contains("交流") || currentChat.name.contains("沙龙")
    }
    
    /// 模拟群聊成员池（供群聊模式随机抽取发言人）
    private let groupMembers = [
        (name: "李阿强", avatar: "person.crop.circle.badge.checkmark"),
        (name: "张大小姐", avatar: "person.circle"),
        (name: "代码搬运工", avatar: "curlybraces"),
        (name: "王总", avatar: "person.box.digits.badge.purple")
    ]
    
    /// 模拟群聊损友语录库
    private let groupReplyTemplates = [
        "好家伙，这个东西说得深刻！",
        "太强了，前排围观大牛 🍿",
        "赞同！我之前在 Mac Mini M1 上跑也是这个结果。",
        "群主发红包！发红包就支持你！",
        "卧槽，这群里真是什么大能都有啊...",
        "收到，晚点看，现在正在疯狂改 Bug 😭",
        "唱首歌吧",
        "本文介绍如何集成声网实时互动 SDK"
    ]
    
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
        if currentChat.messages == nil { currentChat.messages = [] }
        currentChat.messages?.append(newMessage)
        
        // 3. 更新会话摘要展示
        updateSummary(with: newMessage)
        
        // 4. 图片物理缓存保存
        if let data = imageData {
            ImageCacheManager.shared.saveImage(data: data, forKey: "WhatsChatImageCache")
        }
        
        // ==========================================
        // 🔴 核心业务路由分发：单聊回复 vs 群聊盖楼
        // ==========================================
        if isGroupChat {
            // 👉 当前是群聊：唤醒群友盖楼模拟器
            let userContent = type == "text" ? (text ?? "") : "[\(type)]"
            triggerGroupChatFlow(userContent: userContent, afterDelay: isMedia ? 1.5 : 0.0)
        } else {
            // 👉 当前是单聊：维持你原先的 1对1 自动回复逻辑
            if isMedia {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        newMessage.isSending = false // 发送成功，菊花消失
                    }
                    self.save()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        let mockContent = type == "location" ? "[location]" : "[\(type)]"
                        self.mockReply(to: mockContent)
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.mockReply(to: text ?? "")
                }
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

    /// 🟢 单聊 1 对 1 回复机
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
        } else if userContent == "[voice]" {
            replyText = "没听清"
        } else {
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
        //是否正在当前聊天页内
        if !self.isViewingChat {
             self.currentChat.unreadCount += 1
        }
        save()
    }
    
    /// 🔴 新增：群聊多角色“高仿盖楼”队列控制机
    private func triggerGroupChatFlow(userContent: String, afterDelay baseDelay: Double) {
        // 决定本次谁出来接话，随机产生 2 到 3 条回复
        let totalReplies = Int.random(in: 2...3)
        
        for i in 1...totalReplies {
            // 计算时间线：如果是多媒体消息，需要加上多媒体本身的传输延迟基底
            let delay = baseDelay + (Double(i) * 1.5)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                // 1. 随机抽成员与语录
                let member = self.groupMembers.randomElement()!
                let replyText = self.groupReplyTemplates.randomElement()!
                
                let now = Date()
                
                // 2. 灌入群友特异性字段：名字与专属头像
                let groupMessage = Message(
                    text: replyText,
                    time: self.formatTime(now),
                    isFromMe: false,
                    timestamp: now,
                    messageType: "text",
                    senderName: member.name,
                    senderAvatar: member.avatar
                )
                
                // 3. 上屏持久化
                if self.currentChat.messages == nil { self.currentChat.messages = [] }
                self.currentChat.messages?.append(groupMessage)
                
                // 4. 微信群格式摘要：显示 “昵称: 内容”
                self.currentChat.lastMessage = "\(member.name): \(replyText)"
                self.currentChat.lastTimestamp = now
                
                //是否正在当前聊天页内
                if !self.isViewingChat {
                     self.currentChat.unreadCount += 1
                }
                
                self.save()
            }
        }
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
            return fileName
        } catch {
            print("缓存视频失败: \(error)")
            return nil
        }
    }
    
    /// 插入一条音视频通话历史记录
    func sendCallMessage(type: String, duration: TimeInterval) {
        let now = Date()
        let timeString = formatTime(now)
        
        let callMessage = Message(
            text: type == "audio" ? "语音通话" : "视频通话",
            time: timeString,
            isFromMe: true,
            timestamp: now,
            messageType: type == "audio" ? "call_audio" : "call_video"
        )
        callMessage.voiceDuration = duration
        
        if currentChat.messages == nil { currentChat.messages = [] }
        currentChat.messages?.append(callMessage)
        
        currentChat.lastMessage = type == "audio" ? "[语音通话]" : "[视频通话]"
        currentChat.lastTimestamp = now
        
        save()
    }
}
