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
     
    @State private var currentCallContext: CallContext? = nil
    
    @Environment(\.modelContext) private var modelContext
    
    //通讯录管理器
    @StateObject private var contactManager = PhoneContactManager()
    
    var body: some View {
        NavigationStack {
            List {
                // 🟢 Section 1：原有的通话记录列表
                if !callRecords.isEmpty {
                    Section(header: Text("最近通话记录")) {
                        ForEach(callRecords) { record in
                            CallRecordRowView(record: record) { chat, type in
                                self.currentCallContext = CallContext(chat: chat, type: type)
                            }
                        }
                    }
                }
                
                // 🟢 Section 2：动态追加的手机本地通讯录（邀请列表）
                Section(header: Text("手机通讯录 (可邀请联系人)")) {
                    if contactManager.contacts.isEmpty {
                        Text("暂无联系人或未开启通讯录权限")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(contactManager.contacts) { phoneContact in
                            // 渲染高仿的邀请 Row
                            HStack(spacing: 15) {
                                // 灰色小头像
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(Image(systemName: "person.crop.circle.fill").foregroundColor(.gray))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(phoneContact.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(phoneContact.phoneNumber)
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // 🔴 右侧亮起“邀请”按钮
                                Button(action: {
                                    print("准备给 \(phoneContact.name) 发送邀请短信...")
                                    // 未来可以在这里调起系统发短信组件（MFMessageComposeViewController）
                                }) {
                                    Text("邀请")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(15)
                                }
                                .buttonStyle(.plain) // 防止干扰整行点击
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("通话")
            .fullScreenCover(item: $currentCallContext) { context in
                MockCallOverlayView(callType: context.type , chatName: context.chat.name) { duration in
                    // 回拨挂断后，同样给该联系人再落盘一条通话历史
                    // 访问到 modelContext，可以直接调用存储逻辑
                    saveCallbackRecord(to: context.chat, type: context.type, duration: duration)
                }
                
            }
            .onAppear {
                contactManager.fetchContacts()
            }
        }
    }
    
    //  抽取落盘逻辑，让 body 保持整洁
    private func saveCallbackRecord(to chat: ChatSummary, type: CallType, duration: TimeInterval) {
        print("回拨结束，通话时长：\(duration)秒")
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let callbackMessage = Message(
            text: type == .audio ? "语音通话" : "视频通话",
            time: formatter.string(from: now),
            isFromMe: true,
            timestamp: now,
            messageType: type == .audio ? "call_audio" : "call_video"
        )
        callbackMessage.voiceDuration = duration
        
        // 插入消息并更新会话信息
        chat.messages?.append(callbackMessage)
        chat.lastMessage = type == .audio ? "[语音通话]" : "[视频通话]"
        chat.lastTimestamp = now
        
        // 实时保存
        try? modelContext.save()
    }
    
    
    // 动态计算属性：过滤并提取出所有的通话记录，按时间倒序排列
    private var callRecords: [CallRecord] {
        var groupedRecords: [PersistentIdentifier: [Message]] = [:]
        var chatMap: [PersistentIdentifier: ChatSummary] = [:]
        
        // 1. 归拢所有通话消息
        for chat in chats {
            guard let messages = chat.messages else { continue }
            let callMessages = messages.filter { $0.messageType == "call_audio" || $0.messageType == "call_video" }
            
            if !callMessages.isEmpty {
                groupedRecords[chat.id] = callMessages
                chatMap[chat.id] = chat
            }
        }
        
        var finalRecords: [CallRecord] = []
        
        // 2. 对每个联系人的消息按时间排序并进行合并聚合
        for (chatID, messages) in groupedRecords {
            guard let chat = chatMap[chatID] else { continue }
            // 按时间从新到旧排序
            let sortedMessages = messages.sorted { $0.timestamp > $1.timestamp }
            
            if let latestMsg = sortedMessages.first {
                let record = CallRecord(
                    chat: chat,
                    lastCallType: latestMsg.messageType,
                    timestamp: latestMsg.timestamp,
                    duration: latestMsg.voiceDuration ?? 0,
                    isFromMe: latestMsg.isFromMe,
                    count: sortedMessages.count // 🔴 拿到合并后的总次数
                )
                finalRecords.append(record)
            }
        }
        
        // 3. 最终列表整体按最新通话时间倒序排列
        return finalRecords.sorted { $0.timestamp > $1.timestamp }
    }
}
