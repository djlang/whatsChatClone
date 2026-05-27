//
//  CommunityRoomListView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/27.
//

import SwiftUI

/// 虚拟房间列表模型
struct DiscoverRoom: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let hostName: String
    let speakerCount: Int
    let audienceCount: Int
    let tags: [String]
}

struct CommunityRoomListView: View {
    @StateObject private var roomManager = AudioRoomManager.shared
    
    // 模拟大厅里的热门语音房数据
    private let discoverRooms = [
        DiscoverRoom(title: "☕ 饮啖茶食个包 茶话会 (M1/M2 专场)", description: "正在聊：用 Claude Code 配合 SwiftUI 是一种什么体验？", hostName: "dj", speakerCount: 3, audienceCount: 42, tags: ["SwiftUI", "广州", "大厂技术"]),
        DiscoverRoom(title: "🚀 独立开发者搞钱与副业无责任吹水房", description: "正在聊：出海独立 App 如何在第一本月赚到 500 刀？", hostName: "Alex", speakerCount: 5, audienceCount: 128, tags: ["副业", "出海", "独立开发"]),
        DiscoverRoom(title: "🎵 纯音乐吉他/尤克里里深夜电台", description: "正在聊：EchoPulse 调音器背后的 DSP 音频算法分享", hostName: "琴魔", speakerCount: 2, audienceCount: 19, tags: ["AudioKit", "吉他", "深夜食堂"])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 顶部标语
                    Text("发现正在热聊的精彩房间")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    // 房间卡片列表
                    ForEach(discoverRooms) { room in
                        Button(action: {
                            // 💡 核心：点击卡片，直接唤醒全局状态机，空降进入多人语音房！
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                roomManager.joinRoom(title: room.title)
                            }
                        }) {
                            roomCard(for: room)
                        }
                        .buttonStyle(PlainButtonStyle()) // 去掉 Button 自带的蓝色高亮
                    }
                }
                .padding(.top, 10)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("社群语聊房")
        }
    }
    
    // MARK: - 🎨 像素级高仿语音房卡片组件
    private func roomCard(for room: DiscoverRoom) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. 房间标题与标签
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(room.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    // 右侧亮起一个绿色的 Live 呼吸灯
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                
                Text(room.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // 2. 标签横条
            HStack(spacing: 6) {
                ForEach(room.tags, id: \.self) { tag in
                    Text("# \(tag)")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            // 3. 底部麦位群友缩略图与在线人数
            HStack {
                // 模拟群友头像重叠叠加效果 (Avatar Stack)
                HStack(spacing: -10) {
                    ForEach(0..<min(room.speakerCount, 3), id: \.self) { i in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    }
                }
                
                Text("房主: \(room.hostName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                Spacer()
                
                // 人数统计统计
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                        Text("\(room.speakerCount) 麦位")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "headphones")
                        Text("\(room.audienceCount) 听众")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}
