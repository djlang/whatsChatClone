//
//  ChatListView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import SwiftUI
import SwiftData
struct ChatListView: View {
    // 1. 实时查询所有会话，按最后一条消息的时间倒序排列
    @Query(sort: \ChatSummary.lastTimestamp, order: .reverse)
    private var chats: [ChatSummary]
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List(chats) { chat in
              // 2. 点击进入详情页
                NavigationLink(destination: ChatDetailView(chat: chat)) {
                    ChatRowView(chat: chat)
                }
            }
            .listStyle(.plain)
            .navigationTitle("聊天")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "camera")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "square.and.pencil")
                }
            }
            .onAppear {
                addMockDataIfNeeded()
            }
        }
    }
    
    
    // 初始化数据的逻辑（仅当数据库为空时）
    private func addMockDataIfNeeded() {
        guard chats.isEmpty else { return }
        
        let mockData = [
            ChatSummary(name: "张三", imageName: "person.circle.fill", lastMessage: "最近在忙什么？"),
            ChatSummary(name: "李四", imageName: "user2", lastMessage: "明天下午有空开会吗？"),
            ChatSummary(name: "王五", imageName: "user3", lastMessage: "已经收到文件了。")
        ]
        
        for item in mockData {
            modelContext.insert(item)
        }
        
        // 建议显式保存一下
        try? modelContext.save()
    }
}
