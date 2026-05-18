//
//  ChatRowView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/14.
//
import SwiftUI

struct ChatRowView: View {
    let chat: ChatSummary // 直接接收模型对象
    
    var body: some View {
        HStack(spacing: 15) {
           // --- 这里的逻辑可以适配普通图片和系统图标 ---
            Group {
                if chat.imageName.contains(".") { // 简单判断是否为 SF Symbols (通常带点)
                    Image(systemName: chat.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30) // 图标稍微小一点点
                        .padding(12)
                        .background(Color.gray.opacity(0.2)) // 给图标加个底色
                        .foregroundColor(.white)
                        .clipShape(Circle())
                } else {
                    // 普通本地图片
                    Image(chat.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                }
            }
            .frame(width: 55, height: 55) // 统一头像容器大小
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(chat.name)
                        .font(.headline)
                    Spacer()
                    // 显示最后一条消息的时间
//                    Text(formatDate(chat.lastTimestamp))
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
                    // --- 核心优化：智能显示日期/时间 ---
                    if let timestamp = chat.lastTimestamp {
                        Text(timestamp.chatListTimeStr)
                            .font(.caption)
                            .foregroundColor(chat.unreadCount > 0 ? .green : .gray)
                    } else {
                        Text("") // 如果没有任何消息，留空
                    }
                }
                
                HStack {
                    Text(chat.lastMessage) // 这里会自动更新为详情页发出的最新内容
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    Spacer()
                    
                    // --- 红点 UI ---
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20) // 保证圆形
                            .background(Color.green) // WhatsApp 风格用绿色，微信用红色
                            .clipShape(Capsule()) // 超过两位数时自动变成胶囊形
                    }
                }
                
               
                
            }
        }
        .padding(.vertical, 5)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
