//
//  AttachmentGridView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//
import SwiftUI
import PhotosUI // 必须导入
struct AttachmentGridView: View {
    @Environment(\.dismiss) var dismiss
    // 增加一个绑定，用于将选中的图片传给父视图
    @Binding var selectedItem: PhotosPickerItem?
    
    var onTriggerPicker: () -> Void  // 新增：触发第三方选择器的回调
    // 定义四列等分的布局
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(attachmentOptions) { item in
                    menuItemView(item: item)
                        .onTapGesture {
                            if item.title == "图库" {
                                // 在点击事件中执行回调
                                onTriggerPicker()
                            } else {
                                doSome(item.title)
                            }
                        }
            
                }
            }
            .padding(.top, 30)
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
    
    // 提取出来的子视图，保证代码整洁
    @ViewBuilder
    private func menuItemView(item: AttachmentItem) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundColor(item.color)
            }
            
            Text(item.title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func doSome(_ title: String) {
        print(title)
    
    }
}
