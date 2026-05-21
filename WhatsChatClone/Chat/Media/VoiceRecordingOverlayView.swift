//
//  VoiceRecordingOverlayView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/21.
//

import SwiftUI

struct VoiceRecordingOverlayView: View {
    // 状态：是否准备取消（上滑或左滑到取消区域时变红）
    var isCancelled: Bool = false
    var audioLevel: Float // 新增：接收从外面传进来的实时音量 (0.1 ~ 1.0)
    
    var body: some View {
        ZStack {
            // 1. 全屏暗色背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // 2. 居中的状态气泡
            VStack {
                Spacer()
                
                // 绿色提示框
                VStack(spacing: 15) {
                    // --- 动态波纹核心组件 ---
                    HStack(spacing: 6) {
                        // 5根线条，通过乘以不同的基数，制造出中间高、两边低的微信波纹效果
                        WaveBar(level: audioLevel, multiplier: 0.4)
                        WaveBar(level: audioLevel, multiplier: 0.7)
                        WaveBar(level: audioLevel, multiplier: 1.0) // 中间最长
                        WaveBar(level: audioLevel, multiplier: 0.7)
                        WaveBar(level: audioLevel, multiplier: 0.4)
                    }
                    .frame(height: 50) // 限制最大高度
                }
                .frame(width: 160, height: 100)
                // 如果用户滑动到了取消区域，气泡变红，否则是绿色
                .background(isCancelled ? Color.red.opacity(0.8) : Color(red: 0.1, green: 0.75, blue: 0.45))
                .cornerRadius(18)
                
                Spacer()
                
                // 3. 底部操作指引区域
                HStack {
                    Text("取消")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Text("滑动转文字")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(20)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                
                // 最底部松开提示
                Text("松开 传送")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
            }
        }
    }
}

// 提取出一个单独的线条组件
struct WaveBar: View {
    var level: Float
    var multiplier: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white)
            .frame(width: 4, height: max(6, CGFloat(level) * 45 * multiplier))
    }
}
