//
//  AudioRoomOverlayView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/27.
//

import SwiftUI
import Combine

struct AudioRoomOverlayView: View {
    @StateObject private var roomManager = AudioRoomManager.shared
    
    // 九宫格麦位布局
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            // 1. 顶部工具栏
            HStack {
                Button(action: {
                    withAnimation(.spring()) { roomManager.isMinimized = true }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                }
                
                Spacer()
                
                Text("🔊 多人语音房")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatDuration(roomManager.duration))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.trailing)
            }
            .padding(.top, 40)
            
            // 2. 房间标题
            VStack(spacing: 8) {
                Text(roomManager.roomTitle)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Text("房间内共 \(roomManager.speakers.count) 人")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical)
            
            Spacer()
            
            // 3. 🎙️ 核心：麦位九宫格
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(roomManager.speakers) { user in
                    VStack(spacing: 12) {
                        ZStack {
                            // 💡 绿色动态说话涟漪圈
                            if user.isSpeaking {
                                Circle()
                                    .stroke(Color.green, lineWidth: 3)
                                    .frame(width: 85, height: 85)
                                    .scaleEffect(user.isSpeaking ? 1.15 : 1.0)
                                    .opacity(user.isSpeaking ? 0.4 : 1.0)
                                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: user.isSpeaking)
                            }
                            
                            // 头像
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 75, height: 75)
                                .overlay(
                                    Image(systemName: user.avatarName)
                                        .font(.system(size: 35))
                                        .foregroundColor(.white)
                                )
                            
                            // 右下角静音标志
                            if user.isMuted {
                                Image(systemName: "mic.slash.fill")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .foregroundColor(.white)
                                    .offset(x: 25, y: 25)
                            }
                        }
                        
                        // 名字与状态标签
                        HStack(spacing: 4) {
                            Text(user.name)
                                .font(.footnote)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            if !user.isSpeaker {
                                Text("听众")
                                    .font(.system(size: 9))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.5))
                                    .cornerRadius(4)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 4. 底部控制面板
            HStack(spacing: 40) {
                // 静音自己
                Button(action: { roomManager.speakers[0].isMuted.toggle() }) {
                    VStack(spacing: 8) {
                        Image(systemName: roomManager.speakers.first?.isMuted == true ? "mic.slash.fill" : "mic.fill")
                            .font(.title2)
                            .padding()
                            .background(roomManager.speakers.first?.isMuted == true ? Color.red : Color.gray.opacity(0.2))
                            .clipShape(Circle())
                        Text("麦克风").font(.caption)
                    }
                }
                
                // 🔴 挂断退出
                Button(action: { roomManager.leaveRoom() }) {
                    VStack(spacing: 8) {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .padding(20)
                            .background(Color.red)
                            .clipShape(Circle())
                        Text("离开房间").font(.caption).bold()
                    }
                }
                
                // 切换麦位状态（上麦/下麦）
                Button(action: { roomManager.speakers[0].isSpeaker.toggle() }) {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                        Text("举手发言").font(.caption)
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.14).ignoresSafeArea()) // 类似 Clubhouse 的高级暗色底
    }
    
    private func formatDuration(_ totalSeconds: TimeInterval) -> String {
        let mins = Int(totalSeconds) / 60
        let secs = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
