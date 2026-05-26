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
            // 💡 换成滚动视图，背景刷一层 WhatsApp 的淡淡底色
            ScrollView {
                VStack(spacing: 12) { // 🔴 这里可以直接控制每个卡片（Section）之间的上下间距
                    
                    // 1. 个人信息区
                    customCard {
                        profileHeaderView
                    }
                    
                    // 2. 分组一：账户安全
                    customCard {
                        VStack(spacing: 0) {
                            SettingsRow(icon: "key.fill", iconColor: .green, title: "账户", subtitle: "安全通知、更改号码")
                            customDivider
                            SettingsRow(icon: "lock.fill", iconColor: .emeraldGreen, title: "隐私", subtitle: "封锁联系人、限时消息")
                            customDivider
                            SettingsRow(icon: "bubble.left.fill", iconColor: .green, title: "对话", subtitle: "主题、壁纸、聊天记录")
                        }
                    }
                    
                    // 3. 分组二：通知
                    customCard {
                        VStack(spacing: 0) {
                            SettingsRow(icon: "bell.fill", iconColor: .red, title: "通知", subtitle: "消息、群组和铃声")
                            customDivider
                            SettingsRow(icon: "chart.pie.fill", iconColor: .green, title: "存储空间和数据", subtitle: "网络使用情况、自动下载")
                        }
                    }
                    
                    customCard {
                        VStack(spacing: 0) {
                            SettingsRow(icon: "person.2.fill", iconColor: .green, title: "联系人", subtitle: "已保存的联系人、群组")
                            SettingsRow(icon: "face.smiling.fill", iconColor: .teal, title: "动态", subtitle: "隐私设置、动态更新")
                            SettingsRow(icon: "bookmark.fill", iconColor: .green, title: "收藏", subtitle: "添加、重新排序、移除")
                        }
                    }
                    
                    customCard {
                        VStack(spacing: 0) {
                            SettingsRow(icon: "questionmark.circle.fill", iconColor: .blue, title: "帮助", subtitle: "帮助中心、联系我们、隐私政策")
                        }
                    }
                    
                    // 后续分组依此类推...
                }
                .padding(.horizontal, 16) // 控制整体卡片距离屏幕左右两边的间距
                .padding(.top, 10)
            }
            .background(Color(UIColor.systemGroupedBackground)) // 还原高仿灰白底色
            .navigationTitle("设置")
            // .toolbar { ...保持不变 }
        }
    }
    
    // 🎨 核心：自定义卡片容器，像素级掌控弧度
    private func customCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12) // 控制卡片内部的上下内边距
            .background(Color(.systemBackground)) // 卡片自身是纯白
            .cornerRadius(10) // 🔴 像素级微调：在这里任意修改你想要的圆角弧度！
    }
    
    // 🎨 自定义卡片内部的分割线
    private var customDivider: some View {
        Divider()
            .padding(.leading, 43) // 让分割线和文字对齐，左侧不切断图标，完全对齐 WhatsApp 细节
            .padding(.vertical, 8)
    }
    
    // MARK: - 个人信息卡片组件
    private var profileHeaderView: some View {
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


// 辅助颜色扩展，方便对齐 WhatsApp 的各种深浅绿色
extension Color {
    static let emeraldGreen = Color(red: 0.0, green: 0.6, blue: 0.4)
}
