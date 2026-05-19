//
//  LocationFullScreenView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/19.
//

import SwiftUI
import MapKit

struct LocationFullScreenView: View {
    let msg: Message
    @Environment(\.dismiss) var dismiss
    
    // 初始位置设定
    @State private var region: MKCoordinateRegion
    
    init(msg: Message) {
        self.msg = msg
        let lat = msg.latitude ?? 0
        let lon = msg.longitude ?? 0
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // 交互式地图
                Map(initialPosition: .region(region)) {
                    if let lat = msg.latitude, let lon = msg.longitude {
                        Marker(msg.locationName ?? "位置", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // 自定义关闭按钮 (如果不想用 NavigationBar 的话)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                        .background(Color.white.clipShape(Circle()))
                        .padding()
                }
            }
            .navigationTitle(msg.locationName ?? "查看位置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // 扩展：可以加入跳转到系统地图导航的按钮
                    Button("导航") {
                        openInSystemMaps()
                    }
                }
            }
        }
    }
    
    private func openInSystemMaps() {
        guard let lat = msg.latitude, let lon = msg.longitude else { return }
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)))
        destination.name = msg.locationName
        destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
