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
    var time: String
    var isFromMe: Bool
    var timestamp: Date      // 核心：用于物理排序，精确到毫秒
    @Attribute(.externalStorage) var imageData: Data? // 大数据（图片）建议开启外部存储优化
    // 关键：建立反向关联
    var chatSummary: ChatSummary?
    init(text: String, time: String, isFromMe: Bool, imageData: Data? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.time = time
        self.isFromMe = isFromMe
        self.timestamp = timestamp// 记录创建时的精确瞬间
        self.imageData = imageData
        
    }
}
