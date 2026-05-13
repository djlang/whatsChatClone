//
//  ChatSummary.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import Foundation

struct ChatSummary: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let avatar: String // 暂时用 SF Symbols 代替
}

let sampleChats = [
    ChatSummary(name: "张三", lastMessage: "下午有空语音吗？", time: "14:20", avatar: "person.circle.fill"),
    ChatSummary(name: "SwiftUI 学习群", lastMessage: "有人知道 Firebase 怎么配吗？", time: "12:05", avatar: "group.app.fill")
]
