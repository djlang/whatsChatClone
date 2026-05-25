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
    let chatName: String // 💡 新增：接收对话人名称
    var onDismiss: (TimeInterval) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    
    @State private var callState: CallState = .dialing
    
    @State private var isMuted = false
    @State private var isSpeakerOn = false
    @State private var isVideoOff = false
    
    var body: some View {
        ZStack {
            // 背景层
            if callType == .video {
                // 视频通话：显示前置摄像头预览
                if isVideoOff {
                    Color.black.ignoresSafeArea()
                } else {
                    CameraPreview(session: cameraManager.session)
                        .ignoresSafeArea()
                        .background(Color.black)
                }
                
                
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
                    
                    Text(callStatusText)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(radius: callType == .video ? 5 : 0)
                    
                    // 计时器显示：仅接通后显示
                    if callState == .connected {
                        Text(formatDuration(cameraManager.callDuration))
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
                        self.cameraManager.stopSession()
                        self.onDismiss(self.cameraManager.callDuration)
                        self.dismiss()
                    },
                    onFlipCamera: {
                        self.cameraManager.switchCamera()
                    }
                )
                .padding(.bottom, 50)
            }
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
        // 如果是视频通话，立即开启摄像头（在拨号阶段就显示预览）
        if self.callType == .video {
            self.cameraManager.setupCamera()
        }

        // 模拟 3 秒后接通
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut) {
                self.callState = .connected
            }
            
            // 启动计时器
            self.cameraManager.startTimer()
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}
