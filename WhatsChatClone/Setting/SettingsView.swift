//
//  SettingsView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/26.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                // 🟢 头部：个人信息卡片
                profileHeaderSection
                
                // 🟢 分组一：核心账户安全设置
                Section {
                    SettingsRow(icon: "key.fill", iconColor: .green, title: "账户", subtitle: "安全通知、更改号码")
                    SettingsRow(icon: "lock.fill", iconColor: .emeraldGreen, title: "隐私", subtitle: "封锁联系人、限时消息")
                    SettingsRow(icon: "bubble.left.fill", iconColor: .green, title: "对话", subtitle: "主题、壁纸、聊天记录")
                }
                
                // 🟢 分组二：通知与存储
                Section {
                    SettingsRow(icon: "bell.fill", iconColor: .red, title: "通知", subtitle: "消息、群组和铃声")
                    SettingsRow(icon: "chart.pie.fill", iconColor: .green, title: "存储空间和数据", subtitle: "网络使用情况、自动下载")
                }
                
                // 🟢 分组三：社交与辅助
                Section {
                    SettingsRow(icon: "person.2.fill", iconColor: .green, title: "联系人", subtitle: "已保存的联系人、群组")
                    SettingsRow(icon: "face.smiling.fill", iconColor: .teal, title: "动态", subtitle: "隐私设置、动态更新")
                    SettingsRow(icon: "bookmark.fill", iconColor: .green, title: "收藏", subtitle: "添加、重新排序、移除")
                }
                
                // 🟢 分组四：帮助
                Section {
                    SettingsRow(icon: "questionmark.circle.fill", iconColor: .blue, title: "帮助", subtitle: "帮助中心、联系我们、隐私政策")
                }
            }
            .listStyle(.insetGrouped) // 💡 灵魂修饰符：完美复刻圆角卡片分块质感
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { print("搜索设置") }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - 个人信息卡片组件
    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: 15) {
                // 1. 头像
                Image("mock_avatar") // 替换为你项目里的实测头像或占位图
                    .resizable()
                    .scaledToFill()
                    .frame(width: 65, height: 65)
                    .clipShape(Circle())
                    .background(Circle().fill(Color.gray.opacity(0.2)))
                
                // 2. 名字与签名
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alice")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("你好！我正在使用 WhatsApp。")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 3. 右侧二维码
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 通用设置行组件
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 15) {
            // 左侧精美图标背景
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
            
            // 中间文字
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 右侧系统箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(UIColor.lightGray))
        }
        .padding(.vertical, 2)
    }
}

// 辅助颜色扩展，方便对齐 WhatsApp 的各种深浅绿色
extension Color {
    static let emeraldGreen = Color(red: 0.0, green: 0.6, blue: 0.4)
}
