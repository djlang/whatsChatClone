//
//  MockCallOverlayView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/22.
//

import SwiftUI

struct MockCallOverlayView: View {
    let callType: CallType
    var onDismiss: (TimeInterval) -> Void
    let chatName: String // 💡 新增：接收对话人名称
    
    @Environment(\.dismiss) private var dismiss
    @State private var callDuration: TimeInterval = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            // 全屏暗黑高仿背景
            Color(UIColor.darkGray)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
              
                Spacer()
                
                // 对方信息区
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        )
                    
                    Text(callType == .audio ? "语音通话中..." : "视频通话中...")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    // 计时器显示
                    Text(formatDuration(callDuration))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // 控制核心：挂断按钮
                Button(action: {
                    timer?.invalidate()
                    onDismiss(callDuration)
                    dismiss() // 退出全屏
                }) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "phone.down.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // 通话开始，启动计时器
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                callDuration += 1
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}
