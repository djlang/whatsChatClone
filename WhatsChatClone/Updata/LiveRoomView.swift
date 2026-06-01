//
//  LiveRoomView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/29.
//

import SwiftUI
import AVKit
import Combine

// MARK: - 弹幕数据模型
struct LiveDanmaku: Identifiable {
    let id = UUID()
    let name: String
    let text: String
    let color: Color = [.white, .yellow, .cyan, .green].randomElement()!
}

struct LiveRoomView: View {
    let room: LiveRoom
    @Environment(\.dismiss) var dismiss
    
    // 视频播放器状态
    @State private var player: AVPlayer? = nil
    
    // 互动状态
    @State private var inputText: String = ""
    @State private var danmakus: [LiveDanmaku] = []
    @State private var heartCount: Int = 0 // 点赞红心计数
    
    @State private var isFollow: Bool = false
    
    // 模拟群友刷弹幕的定时器
    let timer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()
    
    // 模拟的虚拟弹幕池
    let mockTexts = [
        "卡不卡？我这边很流畅！",
        "M1 Mac Mini 还能再战5年！",
        "主播这套 SwiftUI 架构讲得太通透了",
        "卧槽，单机 Demo 变直播间了？！",
        "666666666",
        "草图理2.0什么时候上线啊？",
        "请教一下，SwiftData 在高并发下表现怎么样？",
        "反手就是一个超大火箭！"
    ]
    let mockNames = ["独立开发刘经理", "SwiftUI大牛", "苹果精神股东", "阿强", "Eva", "dj的粉丝"]

    var body: some View {
        ZStack {
            // ----------------------------------------------------
            // 🔴 层级一：底层流媒体拉流底座 (Player Layer)
            // ----------------------------------------------------
            GeometryReader { geo in
                if let player = player {
                    VideoPlayer(player: player)
                        .disabled(true) // 禁用原生播放器的进度条和控制面板，强制全屏沉浸
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // 视频未加载出来的黑色霓虹占位
                    Color.black
                        .overlay(
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.white)
                                Text("正在连接流媒体服务器...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
            .ignoresSafeArea()
            
            // ----------------------------------------------------
            // 🔴 层级二 & 三：上层互动 UI (Interaction Layer)
            // ----------------------------------------------------
            VStack {
                // 1. 顶部工具栏（主播信息 + 退出按钮）
                headerView
                
                Spacer()
                
                // 2. 中下部：弹幕渲染区域
                danmakuAreaView
                
                // 3. 底部：输入框 + 互动按钮（点赞、送礼）
                bottomActionBar
            }
        }
        .onAppear {
            initLivePlayer()
        }
        .onDisappear {
            destroyLivePlayer()
        }
        // 监听定时器，模拟源源不断的线上观众在刷弹幕
        .onReceive(timer) { _ in
            simulateIncomingDanmaku()
        }
    }
}

// MARK: - 子视图组件拆解
extension LiveRoomView {
    
    // 🟢 顶部主播卡片与关闭按钮
    private var headerView: some View {
        HStack {
            // 主播简要信息
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.streamer)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(room.viewerCount + heartCount) 人在看")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button {
                    // 关注逻辑预留
                    if isFollow {
                        isFollow = false
                    }else {
                        isFollow = true
                    }
                } label: {
                    Text( isFollow ? "已关注" : "关注")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(isFollow ? Color.gray : Color.red)
                        .clipShape(Capsule())
                }
                .padding(.trailing, 4)
            }
            .padding(6)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            .padding(.leading)
            
            Spacer()
            
            // 关闭直播间按钮
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .padding(.trailing)
        }
        .padding(.top, 50) // 越过安全区域
    }
    
    // 🟢 弹幕纵向滚动展示区（高仿微信直播间左下角）
    private var danmakuAreaView: some View {
        HStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(danmakus) { danmaku in
                            HStack(alignment: .top, spacing: 4) {
                                Text("\(danmaku.name):")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(danmaku.color)
                                Text(danmaku.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(6)
                            .id(danmaku.id)
                        }
                    }
                }
                .frame(width: 280, height: 220) // 限制宽度和高度，不挡住画面主体
                .onChange(of: danmakus.count) { _, _ in
                    if let lastId = danmakus.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            Spacer() // 把弹幕推向左侧
        }
        .padding(.leading)
    }
    
    // 🟢 底部操作控制栏
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            // 弹幕文本输入框
            HStack {
                TextField("", text: $inputText, prompt: Text("说点什么...").foregroundColor(.white.opacity(0.6)))
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .submitLabel(.send)
                    .onSubmit {
                        sendUserDanmaku()
                    }
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
            
            // 礼物按钮
            Button {
                let giftDanmaku = LiveDanmaku(name: "我", text: "送出了一个 [超级火箭] 🚀")
                danmakus.append(giftDanmaku)
            } label: {
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
            
            // 点赞爱心按钮
            Button {
                heartCount += 1
                // 用户手动发一条弹幕假装互动
                let likeDanmaku = LiveDanmaku(name: "我", text: "点赞了主播 👍")
                danmakus.append(likeDanmaku)
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
}

// MARK: - 流媒体控制与业务逻辑
extension LiveRoomView {
    
    /// 初始化播放器并开始拉流
    private var streamURLString: String { room.streamURL }

    private func initLivePlayer() {
        guard let url = URL(string: streamURLString) else { return }
        
        // 1. 创建流媒体本地 Asset 模型
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // 2. 注入播放引擎
        let livePlayer = AVPlayer(playerItem: playerItem)
        self.player = livePlayer
        
        // 3. 开启播放
        livePlayer.play()
    }
    
    /// 退出直播间时彻底销毁播放器，释放系统内存和网络带宽
    private func destroyLivePlayer() {
        player?.pause()
        player = nil
    }
    
    /// 用户手动发射弹幕
    private func sendUserDanmaku() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newDanmaku = LiveDanmaku(name: "我", text: inputText)
        danmakus.append(newDanmaku)
        inputText = "" // 清空输入框
    }
    
    /// 模拟后台源源不断推过来的群友弹幕
    private func simulateIncomingDanmaku() {
        // 限制弹幕池长度，防止长驻留导致内存溢出
        if danmakus.count > 50 {
            danmakus.removeFirst(10)
        }
        
        let randomName = mockNames.randomElement()!
        let randomText = mockTexts.randomElement()!
        
        let incoming = LiveDanmaku(name: randomName, text: randomText)
        danmakus.append(incoming)
    }
}
