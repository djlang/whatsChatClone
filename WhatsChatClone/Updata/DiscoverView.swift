//
//  DiscoverView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/29.
//

import SwiftUI

struct DiscoverView: View {
    // 模拟的直播间数据
    let mockLiveRooms = [
        LiveRoom(id: "1", title: "M1 Mac Mini 独立开发爆肝日记", streamer: "代码搬运工", coverImage: "desktopcomputer", viewerCount: 1240, streamURL: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"),
        LiveRoom(id: "2", title: "WhatsChatClone 2.0 架构重构直播", streamer: "dj", coverImage: "iphone", viewerCount: 888, streamURL: "https://sfux-ext.sfux.info/hls/chapter/6042/1.m3u8")
    ]
    
    @State private var selectedRoom: LiveRoom? = nil
    @State private var isShowingAnchorView = false // 🟢 新增：控制主播开播页的弹窗开关
    
    var body: some View {
        NavigationStack {
            List(mockLiveRooms) { room in
                Button {
                    selectedRoom = room
                } label: {
                    HStack(spacing: 15) {
                        // 直播封面模拟
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gradientBackground)
                                .frame(width: 100, height: 70)
                                .overlay(
                                    Image(systemName: room.coverImage)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )
                            
                            // 🔴 “直播中”闪烁标签
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                                .padding(4)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(room.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text("主播: \(room.streamer)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                Text("\(room.viewerCount) 人在看")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("动态")
            // 💡 点击后直接拉起全屏沉浸式直播间
            .fullScreenCover(item: $selectedRoom) { room in
                LiveRoomView(room: room)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAnchorView = true
                    } label: {
                        Image(systemName: "video.badge.plus") // 摄像机带加号图标
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
               
            }
            // 🔴 主播推流入口：点击右上角摄像机后，满屏拉起你的真机推流镜头
            .fullScreenCover(isPresented: $isShowingAnchorView) {
                AnchorLiveView()
            }
        }
    }
}


extension Color {
    static let gradientBackground = LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
}
