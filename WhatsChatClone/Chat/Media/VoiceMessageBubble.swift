//
//  VoiceMessageBubble.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/20.
//

import SwiftUI

struct VoiceMessageBubble: View {
    let msg: Message
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if !msg.isFromMe {
                voiceIcon
            }
            
            // 长度自适应逻辑
            let duration = msg.voiceDuration ?? 1.0
            let calculatedWidth = 60 + CGFloat(min(duration, 60) / 60.0) * 140
            
            Spacer().frame(width: calculatedWidth)
            
            if msg.isFromMe {
                voiceIcon.rotationEffect(.degrees(180))
            }
            
            Text("\(Int(duration))\"")
                .font(.system(size: 14))
                .foregroundColor(msg.isFromMe ? .white.opacity(0.8) : .gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(msg.isFromMe ? Color(red: 0.1, green: 0.8, blue: 0.3) : Color.white)
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
    
    // 动态变化的声波图标
    private var voiceIcon: some View {
        Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
            .font(.system(size: 16))
            .foregroundColor(msg.isFromMe ? .white : .gray)
            .contentTransition(.symbolEffect(.replace))
//            .symbolEffect(.bounce, options: .repeating, value: isPlaying) // iOS 17 动画
            .symbolEffect(.variableColor.iterative.nonReversing, options: .repeating, value: isPlaying)
            .id("\(msg.id)-\(isPlaying)")   
    }
}
