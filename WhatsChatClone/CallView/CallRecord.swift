//
//  CallRecord.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/25.
//

import Foundation

/// 用于在通话列表展示的模型
struct CallRecord: Identifiable {
    let id: UUID = UUID()
    let chat: ChatSummary      // 🔴 直接持有会话引用，方便回拨
//    let chatName: String       // 谁打来的 / 打给谁
//    let callType: String       // "call_audio" 或 "call_video"
    let lastCallType: String
    let timestamp: Date        // 通话时间
    let duration: TimeInterval // 通话时长
    let isFromMe: Bool         // 是呼出还是呼入
    let count: Int              // 🔴 新增：合并后的通话总次数
}

struct CallContext: Identifiable {
    let id = UUID()
    let chat: ChatSummary
    let type: CallType
}
