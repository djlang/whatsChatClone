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
    let chatName: String       // 谁打来的 / 打给谁
    let callType: String       // "call_audio" 或 "call_video"
    let timestamp: Date        // 通话时间
    let duration: TimeInterval // 通话时长
    let isFromMe: Bool         // 是呼出还是呼入
}
