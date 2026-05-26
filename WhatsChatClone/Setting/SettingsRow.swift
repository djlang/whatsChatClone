//
//  SettingsRow.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/26.
//

// MARK: - 通用设置行组件
import SwiftUI

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
