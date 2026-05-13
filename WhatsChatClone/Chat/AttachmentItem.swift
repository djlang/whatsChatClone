//
//  AttachmentItem.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//
import SwiftUI

struct AttachmentItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

let attachmentOptions = [
    AttachmentItem(title: "相机", icon: "camera.fill", color: .pink),
    AttachmentItem(title: "图库", icon: "photo.fill", color: .purple),
    AttachmentItem(title: "文档", icon: "doc.fill", color: .indigo),
    AttachmentItem(title: "音频", icon: "headphones", color: .orange),
    AttachmentItem(title: "位置", icon: "mappin.and.ellipse", color: .green),
    AttachmentItem(title: "联系人", icon: "person.fill", color: .blue)
]
