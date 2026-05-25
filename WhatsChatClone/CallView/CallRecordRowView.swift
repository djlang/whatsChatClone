//
//  CallRecordRowView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/25.
//

import SwiftUI

struct CallRecordRowView: View {
    let record: CallRecord // 上面定义的 CallRecord 模型
    
    var body: some View {
        HStack(spacing: 15) {
            // 1. 头像
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 45, height: 45)
                .overlay(Image(systemName: "person.fill").foregroundColor(.white))
            
            // 2. 文本信息
            VStack(alignment: .leading, spacing: 4) {
                Text(record.chatName)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 5) {
                    // 呼入呼出箭头标识
                    Image(systemName: record.isFromMe ? "arrow.up.forward.square.fill" : "arrow.down.left.square.fill")
                        .font(.caption)
                        .foregroundColor(record.isFromMe ? .green : .blue)
                    
                    Text(record.timestamp.chatDateHeader)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if record.duration > 0 {
                        Text("(\(formatDuration(record.duration)))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // 3. 右侧回拨动作按钮
            Image(systemName: record.callType == "call_audio" ? "phone" : "video")
                .foregroundColor(.accentColor)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
    
    // 辅助时间格式化、时长格式化方法...
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}
