//
//  CallHistoryListView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/25.
//

import SwiftUI
import SwiftData

struct CallHistoryListView: View {
    // 1. 查出所有会话
    @Query(sort: \ChatSummary.lastTimestamp, order: .reverse) private var chats: [ChatSummary]
    
    // 2. 动态计算属性：过滤并提取出所有的通话记录，按时间倒序排列
    private var callRecords: [CallRecord] {
        var records: [CallRecord] = []
        
        for chat in chats {
            guard let messages = chat.messages else { continue }
            // 过滤出 call_audio 和 call_video 的消息
            let callMessages = messages.filter { $0.messageType == "call_audio" || $0.messageType == "call_video" }
            
            for msg in callMessages {
                let record = CallRecord(
                    chatName: chat.name,
                    callType: msg.messageType,
                    timestamp: msg.timestamp,
                    duration: msg.voiceDuration ?? 0, // 读取通话时长
                    isFromMe: msg.isFromMe
                )
                records.append(record)
            }
        }
        
        // 按照通话时间从新到旧排序
        return records.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if callRecords.isEmpty {
                    ContentUnavailableView("无通话记录", systemImage: "phone.badge.plus", description: Text("你打出的语音和视频通话会显示在这里。"))
                } else {
                    List(callRecords) { record in
                        CallRecordRowView(record: record)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("通话")
        }
    }
}
