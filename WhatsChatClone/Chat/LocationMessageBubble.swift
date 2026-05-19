//
//  LocationMessageBubble.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/19.
//
import SwiftUI
import MapKit

struct LocationMessageBubble: View {
    let msg: Message // 直接传入模型，减少外部取值的逻辑
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 静态地图预览
            if let lat = msg.latitude, let lon = msg.longitude {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )))
                .frame(width: 220, height: 120)
                .allowsHitTesting(false)
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
    }
}
