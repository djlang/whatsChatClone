//
//  CallRecordRowView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/25.
//

import SwiftUI

struct CallRecordRowView: View {
    let record: CallRecord // 上面定义的 CallRecord 模型
    //回拨
    var onCallTriggered: (ChatSummary, CallType) -> Void
    var body: some View {
        HStack(spacing: 15) {
            // 1. 头像
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 45, height: 45)
                .overlay(Image(systemName: "person.fill").foregroundColor(.white))
            
            // 2. 文本信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.chat.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if record.count > 1 {
                        Text("(\(record.count))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                
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
            HStack(spacing: 4) {
                // 按钮 A：一键语音回拨
                Button(action: {
                    onCallTriggered(record.chat, .audio)
                }) {
                    Image(systemName: "phone")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 40, height: 40) // 独立且精准的点击热区
                }
                .buttonStyle(.plain)
                // 按钮 B：一键视频回拨
                Button(action: {
                    onCallTriggered(record.chat, .video)
                }) {
                    Image(systemName: "video")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 40, height: 40) // 独立且精准的点击热区
                }
                .buttonStyle(.plain)
            }
            
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // 确保整行的空白处也能响应点击
        .onTapGesture {
            // 暂时搁置：未来这里点击进入联系人详情页
            print("点击了整行，准备进入 \(record.chat.name) 的详情页")
        }
    }
    
    // 辅助时间格式化、时长格式化方法...
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}
