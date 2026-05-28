//
//  VideoMessageBubble.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/19.
//
import SwiftUI

struct VideoMessageBubble: View {
    let msg: Message
    
    @State private var displayImage: UIImage? = nil
    @State private var isLoading = false
    
    init(msg: Message) {
        self.msg = msg
    }
    
    var body: some View {
        ZStack {
            if let uiImage = displayImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            } else {
                // 封面图缺失或加载中的占位色块
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .opacity(isLoading ? 1 : 0)
                    )
            }
            
            // 视频标识
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
                .shadow(radius: 5)
        }
        .frame(width: 200, height: 200)
        .cornerRadius(10)
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        if displayImage != nil { return }
        isLoading = true
        
        let image = await Task.detached(priority: .userInitiated) {
            return await ImageCacheManager.shared.image(forKey: msg.id.uuidString, targetSize: CGSize(width: 200, height: 200))
        }.value
        
        await MainActor.run {
            withAnimation(.easeIn(duration: 0.2)) {
                self.displayImage = image
                self.isLoading = false
            }
        }
        
        // 兜底逻辑
        if displayImage == nil, let data = msg.imageData {
             if let fallbackImage = UIImage(data: data) {
                 await MainActor.run {
                     self.displayImage = fallbackImage
                 }
             }
        }
    }
}
