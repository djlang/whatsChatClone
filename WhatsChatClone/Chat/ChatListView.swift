//
//  ChatListView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import SwiftUI
import SwiftData
struct ChatListView: View {
  
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @Query(sort: \ChatSummary.lastTimestamp, order: .reverse)
    private var allChats: [ChatSummary]
    
//    private var chats: [ChatSummary]
    @State private var isShowingAddContact = false // 控制弹窗显示
    
    // 过滤后的列表
    var filteredChats: [ChatSummary] {
        if searchText.isEmpty {
            return allChats
        } else {
            return allChats.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredChats) { chat in
                  // 2. 点击进入详情页
                    NavigationLink(destination: ChatDetailView(chat: chat)) {
                        ChatRowView(chat: chat)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(chat)
                            try? modelContext.save()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
                
            }
            .listStyle(.plain)
            .navigationTitle("聊天")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "camera")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddContact = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .onAppear {
                addMockDataIfNeeded()
            }
            .searchable(text: $searchText, prompt: "搜索联系人")
            // 弹出新增页面
            .sheet(isPresented: $isShowingAddContact) {
                AddContactView()
            }
        }
    }
    
    
    // 初始化数据的逻辑（仅当数据库为空时）
    private func addMockDataIfNeeded() {
        guard allChats.isEmpty else { return }
        
        let mockData = [
            ChatSummary(name: "张三", imageName: "person.circle.fill", lastMessage: "最近在忙什么？"),
            ChatSummary(name: "李四", imageName: "sun.min.fill", lastMessage: "明天下午有空开会吗？"),
            ChatSummary(name: "王五", imageName: "car.rear.waves.up.fill", lastMessage: "已经收到文件了。")
        ]
        
        for item in mockData {
            modelContext.insert(item)
        }
        
        // 建议显式保存一下
        try? modelContext.save()
    }
    
    private func deleteChats(at offsets: IndexSet) {
        for index in offsets {
            let chatToDelete = filteredChats[index]
            modelContext.delete(chatToDelete)
        }
        
        // 尝试保存更改
        try? modelContext.save()
    }
}
