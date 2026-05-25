//
//  MainTabBarView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
import SwiftUI

struct MainTabBarView: View {
    var body: some View {
        TabView {
            Text("Status View").tabItem { Label("状态", systemImage: "circle.dashed") }
//            Text("Calls View").tabItem { Label("通话", systemImage: "phone") }
            CallHistoryListView().tabItem { Label("通话", systemImage: "phone") }
            
            // 这是我们要重点做的模块
            ChatListView().tabItem { Label("聊天", systemImage: "message.fill") }
            
            Text("Settings View").tabItem { Label("设置", systemImage: "gear") }
        }
        .accentColor(Color(hex: "#008069"))// 设置 Tab 选中的主题色
    }
}

#Preview {
    MainTabBarView()
}
