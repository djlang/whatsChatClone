//
//  MockCallOverlayView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/22.
//

import SwiftUI
import Combine

struct MockCallOverlayView: View {
    let callType: CallType
    let chatName: String // 💡 新增：接收对话人名称
    var onDismiss: (TimeInterval) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    
    @State private var callDuration: TimeInterval = 0
    @State private var timer: Timer? = nil
    
    @State private var isMuted = false
    @State private var isSpeakerOn = false
    
    var body: some View {
        ZStack {
            // 背景层
            if callType == .video {
                // 视频通话：显示前置摄像头预览
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
                    .background(Color.black)
            } else {
                // 语音通话：显示灰色背景
                Color(UIColor.darkGray)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 40) {
              
                Spacer()
                
                // 对方信息区
                VStack(spacing: 16) {
                    if callType == .audio {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Text(chatName)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(radius: callType == .video ? 5 : 0)
                    
                    Text(callType == .audio ? "语音通话中..." : "视频通话中...")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(radius: callType == .video ? 5 : 0)
                    
                    // 计时器显示
                    Text(formatDuration(callDuration))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(radius: callType == .video ? 5 : 0)
                }
                
                Spacer()
                
                // 控制核心
                HStack(spacing: 40) {
                    // 麦克风开关
                    Button(action: { isMuted.toggle() }) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(isMuted ? Color.white : Color.white.opacity(0.2))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                                        .font(.title2)
                                        .foregroundColor(isMuted ? .black : .white)
                                )
                            Text("静音")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 挂断按钮
                    Button(action: {
                        timer?.invalidate()
                        cameraManager.stopSession()
                        onDismiss(callDuration)
                        dismiss() // 退出全屏
                    }) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Image(systemName: "phone.down.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                )
                            Text("挂断")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 外放开关
                    Button(action: { isSpeakerOn.toggle() }) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(isSpeakerOn ? Color.white : Color.white.opacity(0.2))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Image(systemName: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.1.fill")
                                        .font(.title2)
                                        .foregroundColor(isSpeakerOn ? .black : .white)
                                )
                            Text("外放")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // 通话开始，启动计时器
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                callDuration += 1
            }
            
            // 如果是视频通话，初始化摄像头
            if callType == .video {
                cameraManager.setupCamera()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}
