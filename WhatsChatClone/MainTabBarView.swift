//
//  MainTabBarView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
import SwiftUI
import SwiftData

struct MainTabBarView: View {
    // 悬浮窗通话
    @StateObject private var callManager = OverlayCallManager.shared
    @Environment(\.modelContext) private var modelContext
    
    // 用来控制拖拽悬浮窗的位置状态
    @State private var dragOffset: CGSize = CGSize(width: 130, height: -180)
    
    var body: some View {
        
        ZStack {
            TabView {
                Text("Status View").tabItem { Label("状态", systemImage: "circle.dashed") }
    //            Text("Calls View").tabItem { Label("通话", systemImage: "phone") }
                CallHistoryListView().tabItem { Label("通话", systemImage: "phone") }
                
                // 这是我们要重点做的模块
                ChatListView().tabItem { Label("聊天", systemImage: "message.fill") }
                
                SettingsView().tabItem { Label("设置", systemImage: "gear") }
    //            Text("Settings View").tabItem { Label("设置", systemImage: "gear") }
            }
            .accentColor(Color(hex: "#008069"))// 设置 Tab 选中的主题色
            
            // 悬浮窗
            if callManager.currentMode == .fullScreen {
                // 全屏模式：彻底覆盖盖满
                MockCallOverlayView(
                    callType: callManager.activeType,
                    chatName: callManager.activeChat?.name ?? "未知联系人",
                    onHangup: { finalDuration in
                        // 点击挂断：落盘 SwiftData 并关闭
                        if let chat = callManager.activeChat {
                            saveCallbackRecord(to: chat, type: callManager.activeType, duration: finalDuration)
                        }
                        callManager.endCall()
                    },
                    onMinimize: {
                        // 💡 核心修复：点击缩小，状态机切到 minimized，全屏视图会立刻丝滑退场！
                        withAnimation(.spring()) {
                            callManager.currentMode = .minimized
                        }
                    }
                )
                .transition(.move(edge: .bottom))
            }else if callManager.currentMode == .minimized {
                // 缩小状态：渲染一个可拖拽的精美小悬浮窗
                minimizedCallBubble
            }
            
        }
      
    }
    
    // MARK: - 小悬浮窗组件
    private var minimizedCallBubble: some View {
        VStack(spacing: 6) {
            // 💡 修复三：图标类型跟随当前真实的通话类型动态改变
            Image(systemName: callManager.activeType == .audio ? "phone.fill" : "video.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            Text(formatDuration(callManager.duration))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(width: 75, height: 75)
        .background(Color.green.opacity(0.9)) // 用 WhatsApp 经典绿做悬浮底色
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.dragOffset = CGSize(
                        width: value.startLocation.x + value.translation.width - UIScreen.main.bounds.width/2,
                        height: value.startLocation.y + value.translation.height - UIScreen.main.bounds.height/2
                    )
                }
        )
        // 💡 修复四：点击悬浮窗，只是把模式改回全屏，绝不触发 startCall()，所以不会重新拨号！
        .onTapGesture {
            withAnimation(.spring()) {
                callManager.currentMode = .fullScreen
            }
        }
    }
    
    private func formatDuration(_ totalSeconds: TimeInterval) -> String {
        let mins = Int(totalSeconds) / 60
        let secs = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // 先前在 CallHistoryListView 里的 SwiftData 存储代码，直接搬到这里
    private func saveCallbackRecord(to chat: ChatSummary, type: CallType, duration: TimeInterval) {
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
        
        if chat.messages == nil { chat.messages = [] }
        chat.messages?.append(callbackMessage)
        
        chat.lastMessage = type == .audio ? "[语音通话]" : "[视频通话]"
        chat.lastTimestamp = now
        try? modelContext.save()
    }
}

#Preview {
    MainTabBarView()
}
