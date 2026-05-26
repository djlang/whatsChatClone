//
//  MockCallOverlayView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/22.
//

import SwiftUI
import Combine
import AVFoundation

enum CallState {
    case dialing
    case connected
}

struct MockCallOverlayView: View {
    let callType: CallType
    let chatName: String
    
    // 💡 升级两个回调：挂断和缩小
    var onHangup: (TimeInterval) -> Void
    var onMinimize: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var callManager = OverlayCallManager.shared // 🔴 引入全局管理器
    
    @State private var callState: CallState = .dialing
    @State private var isMuted = false
    @State private var isSpeakerOn = false
    @State private var isVideoOff = false
    
    var body: some View {
        ZStack {
            // 背景层
            if callType == .video {
                if isVideoOff {
                    Color.black.ignoresSafeArea()
                } else {
                    CameraPreview(session: cameraManager.session)
                        .ignoresSafeArea()
                        .background(Color.black)
                }
            } else {
                Color(UIColor.darkGray).ignoresSafeArea()
            }
            
            VStack {
                // 顶部工具栏
                HStack {
                    // 🔴 修复一：缩小按钮不仅负责样式，还要准确触发全局状态跳变
                    Button(action: {
                        print("📱 用户点击缩小按钮")
                        // 1. 停掉本地 CameraManager 自带的本地计时器（防止重复计时）
                        // 2. 触发主页面的收起闭包
                        onMinimize()
                    }) {
                        Image(systemName: "rectangle.inset.bottomright.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
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
                        
                        Text(callStatusText)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .shadow(radius: callType == .video ? 5 : 0)
                        
                        // 💡 修复二：计时器时间改由全局 `callManager.duration` 统一提供！
                        // 这样全屏和缩小悬浮窗看的是同一个秒数，绝对同步！
                        if callState == .connected {
                            Text(formatDuration(callManager.duration))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .shadow(radius: callType == .video ? 5 : 0)
                                .transition(.opacity)
                        }
                    }
                    
                    Spacer()
                    
                    // 控制核心
                    CallControlsView(
                        callType: self.callType,
                        isMuted: $isMuted,
                        isSpeakerOn: $isSpeakerOn,
                        isVideoOff: $isVideoOff,
                        onHangup: {
                            print("🔴 用户点击全屏挂断")
                            self.cameraManager.stopSession()
                            // 触发落盘并关闭
                            self.onHangup(callManager.duration)
                        },
                        onFlipCamera: {
                            self.cameraManager.switchCamera()
                        }
                    )
                    .padding(.bottom, 50)
                }
            }
            .padding(.top, 40)
        }
        .onAppear {
            self.startCallFlow()
        }
        .onDisappear {
            self.cameraManager.stopSession()
        }
    }
    
    private var callStatusText: String {
        if callState == .dialing {
            return "等待对方接受邀请"
        } else {
            return callType == .audio ? "语音通话中..." : "视频通话中..."
        }
    }
    
    private func startCallFlow() {
        // 🟢 核心修复：检查全局状态机。如果已经接通了，直接维持 connected，禁止二次拨号！
        if callManager.isCallConnected {
            self.callState = .connected
            if self.callType == .video {
                self.cameraManager.setupCamera() // 如果是视频，依然需要重新唤醒摄像头画面
            }
            return
        }
        if self.callType == .video {
            self.cameraManager.setupCamera()
        }

        // 模拟 3 秒后接通
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard callManager.currentMode == .fullScreen else {
                callManager.isCallConnected = true
                return
            }
            withAnimation(.easeInOut) {
                self.callState = .connected
            }
            // 🔴 告诉全局管理器：已经接通，全局计时器开始走字
            callManager.isCallConnected = true
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}
