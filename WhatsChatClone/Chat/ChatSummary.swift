//
//  ChatSummary.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import Foundation
import SwiftData

//struct ChatSummary: Identifiable {
//    let id = UUID()
//    let name: String
//    let lastMessage: String
//    let time: String
//    let avatar: String // 暂时用 SF Symbols 代替
//}
//
//let sampleChats = [
//    ChatSummary(name: "张三", lastMessage: "下午有空语音吗？", time: "14:20", avatar: "person.circle.fill"),
//    ChatSummary(name: "SwiftUI 学习群", lastMessage: "有人知道 Firebase 怎么配吗？", time: "12:05", avatar: "group.app.fill")
//]


@Model
final class ChatSummary {
    @Attribute(.unique) var id: UUID
    var name: String
    var imageName: String
    
    // 关键：定义一对多关系。删除会话时级联删除消息。
    @Relationship(deleteRule: .cascade, inverse: \Message.chatSummary)
    var messages: [Message]? = []
    
    // 用于首页显示的冗余数据，方便排序和预览
    var lastMessage: String = ""
    var lastTimestamp: Date?
    var unreadCount: Int = 0 // 新增字段，默认为 0
 
    init(id: UUID = UUID(), name: String, imageName: String, lastMessage: String = "", lastTimestamp: Date? = nil, unreadCount: Int = 0) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.lastMessage = lastMessage
        self.lastTimestamp = lastTimestamp
        self.unreadCount = unreadCount
    }
}
