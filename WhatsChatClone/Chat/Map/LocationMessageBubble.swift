//
//  LocationMessageBubble.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/19.
//
import SwiftUI
import MapKit

struct LocationMessageBubble: View, MessageRenderable {
    let msg: Message
    
    init(msg: Message) {
        self.msg = msg
    }
    
    @State private var isShowingFullScreenMap = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 静态地图预览
            if let lat = msg.latitude, let lon = msg.longitude {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )))
                .frame(width: 220, height: 120)
                .allowsHitTesting(false) // 保持地图本身不可点击，以便父视图接收手势
            }
            
            // 地点名称
            Text(msg.locationName ?? "未知地点")
                .font(.system(size: 14))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(width: 220, alignment: .leading) // 固定宽度确保对齐
                .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            isShowingFullScreenMap = true
        }
        .fullScreenCover(isPresented: $isShowingFullScreenMap) {
            LocationFullScreenView(msg: msg)
        }
        .contextMenu {
            Button(role: .destructive) {
                // Delete logic needs access to the environment or a closure
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

}
