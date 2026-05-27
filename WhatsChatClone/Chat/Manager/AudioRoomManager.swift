//
//  AudioRoomManager.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/27.
//

import SwiftUI
import Combine
/// 麦位用户模型
struct RoomUser: Identifiable {
    let id = UUID()
    let name: String
    let avatarName: String
    var isSpeaking: Bool = false
    var isMuted: Bool = false
    var isSpeaker: Bool = true // true: 发言者, false: 听众
}

final class AudioRoomManager: ObservableObject {
    static let shared = AudioRoomManager()
    private init() {}
    
    @Published var isRoomActive: Bool = false
    @Published var isMinimized: Bool = false
    @Published var roomTitle: String = "iOS 技术技术交流私享会"
    @Published var duration: TimeInterval = 0
    @Published var speakers: [RoomUser] = []
    
    private var roomTimer: Timer?
    private var mockSpeakingTimer: Timer?
    
    /// 开启/加入语音房
    func joinRoom(title: String) {
        self.roomTitle = title
        self.isRoomActive = true
        self.isMinimized = false
        self.duration = 0
        
        // 1. 初始化几个高仿的群友麦位
        self.speakers = [
            RoomUser(name: "我", avatarName: "person.crop.circle.fill", isSpeaker: true),
            RoomUser(name: "李阿强", avatarName: "person.crop.circle.badge.checkmark", isSpeaker: true),
            RoomUser(name: "张大小姐", avatarName: "person.circle", isSpeaker: true),
            RoomUser(name: "王总", avatarName: "person.box.digits.badge.purple", isSpeaker: false) // 听众
        ]
        
        // 2. 开启房间总计时
        roomTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.duration += 1 }
        }
        
        // 3. 🔴 核心黑魔法：模拟群友动态说话（每隔 2 秒随机让某个机器人说话）
        mockSpeakingTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                for index in 0..<self.speakers.count {
                    if index == 0 { continue } // “我”不自动说话
                    // 随机决定这个机器人是开麦还是闭麦，营造超真实的群聊气氛
                    self.speakers[index].isSpeaking = Bool.random() && self.speakers[index].isSpeaker
                }
            }
        }
    }
    
    /// 退出房间
    func leaveRoom() {
        roomTimer?.invalidate()
        mockSpeakingTimer?.invalidate()
        roomTimer = nil
        mockSpeakingTimer = nil
        self.isRoomActive = false
        self.isMinimized = false
    }
}
