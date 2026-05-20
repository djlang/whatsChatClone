//
//  VideoMessageBubble.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/19.
//
import SwiftUI

struct VideoMessageBubble: View {
    let msg: Message
    
    var body: some View {
        ZStack {
            // 尝试显示视频封面图 (存储在 imageData 中)
            if let thumbData = msg.imageData, let uiImage = UIImage(data: thumbData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .cornerRadius(10)
            } else {
                // 封面图缺失时的占位色块
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .cornerRadius(10)
            }
            
            // 视频标识
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
                .shadow(radius: 5)
        }
    }
}
