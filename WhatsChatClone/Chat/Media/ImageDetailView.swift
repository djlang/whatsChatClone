//
//  ImageDetailView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/13.
//

import SwiftUI

struct ImageDetailView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss // 用于关闭页面
    @State private var scale: CGFloat = 1.0 // 用于双指缩放
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss() // 点击黑色背景退出
                }
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                // 简单的双指缩放手势
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                scale = 1.0 // 放开后回弹
                            }
                        }
                )
                .onTapGesture(count: 1) {
                    dismiss()
                }
            
        }
        .overlay(alignment: .topTrailing) {
            // 右上角关闭按钮
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            }
        }
        .onTapGesture {
            dismiss() // 点击背景也能退出
        }
    }
}
