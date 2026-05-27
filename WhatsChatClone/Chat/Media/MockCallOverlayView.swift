//
//  MockCallOverlayView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/22.
//

import SwiftUI
import Combine
import AVFoundation



struct MockCallOverlayView: View {
    let callType: CallType
    let chatName: String
    var onHangup: (TimeInterval) -> Void
    var onMinimize: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var callManager = OverlayCallManager.shared
    
    @State private var callState: CallState = .dialing
    @State private var isMuted = false
    @State private var isSpeakerOn = false
    @State private var isVideoOff = false
    
    // 🔴 状态机：true 表示自己是大窗，对方是小窗；false 表示对方是大窗，自己是小窗
    @State private var isLocalVideoMain = true
    
    var body: some View {
        ZStack {
            // ==========================================
            // 🛡️ 视图一：对方的画面（模拟远程流）
            // ==========================================
            remoteVideoViewMock
                .ignoresSafeArea()
                // 💡 核心魔法一：当对方是小窗时，强行用 modifier 把它缩成右上角小方块
                .frame(width: isLocalVideoMain ? 110 : UIScreen.main.bounds.width,
                       height: isLocalVideoMain ? 160 : UIScreen.main.bounds.height)
                .cornerRadius(isLocalVideoMain ? 12 : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: isLocalVideoMain ? 12 : 0)
                        .stroke(Color.white.opacity(isLocalVideoMain ? 0.5 : 0), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(isLocalVideoMain ? 0.3 : 0), radius: 8)
                // 算好小窗在右上角的偏移量
                .position(
                    x: isLocalVideoMain ? UIScreen.main.bounds.width - 71 : UIScreen.main.bounds.width / 2,
                    y: isLocalVideoMain ? 140 : UIScreen.main.bounds.height / 2
                )
                .zIndex(isLocalVideoMain ? 2 : 0) // 对方是小窗时，层级盖在最上方
                .opacity(callState == .connected && !isVideoOff ? 1 : (isLocalVideoMain ? 0 : 1)) // 没接通时隐藏小窗
                .onTapGesture {
                    if isLocalVideoMain { toggleVideoWindow() }
                }

            // ==========================================
            // 🛡️ 视图二：我的画面（本地摄像头，雷打不动，绝不销毁）
            // ==========================================
            Group {
                if callType == .video && !isVideoOff {
                    CameraPreview(session: cameraManager.session)
                } else {
                    Color(UIColor.darkGray)
                }
            }
            .ignoresSafeArea()
            // 💡 核心魔法二：当自己是小窗时，同样强行缩成右上角小方块
            .frame(width: isLocalVideoMain ? UIScreen.main.bounds.width : 110,
                   height: isLocalVideoMain ? UIScreen.main.bounds.height : 160)
            .cornerRadius(isLocalVideoMain ? 0 : 12)
            .overlay(
                RoundedRectangle(cornerRadius: isLocalVideoMain ? 0 : 12)
                    .stroke(Color.white.opacity(isLocalVideoMain ? 0 : 0.5), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(isLocalVideoMain ? 0 : 0.3), radius: 8)
            .position(
                x: isLocalVideoMain ? UIScreen.main.bounds.width / 2 : UIScreen.main.bounds.width - 71,
                y: isLocalVideoMain ? UIScreen.main.bounds.height / 2 : 140
            )
            .zIndex(isLocalVideoMain ? 0 : 2) // 自己是小窗时，层级盖在最上方
            .onTapGesture {
                if !isLocalVideoMain { toggleVideoWindow() }
            }

            // ==========================================
            // 🛠️ 视图三：UI 控件层（永远在最顶层，zIndex 最高）
            // ==========================================
            VStack {
                // 顶部工具栏
                HStack {
                    Button(action: {
                        print("📱 用户点击缩小按钮")
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
                    if callState == .dialing || callType == .audio || !isLocalVideoMain {
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
                                .shadow(radius: 5)
                            
                            Text(callStatusText)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                            
                            if callState == .connected {
                                Text(formatDuration(callManager.duration))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                    .shadow(radius: 5)
                            }
                        }
                    } else {
                        // 自己在大窗时，顶部胶囊计时器
                        Text(formatDuration(callManager.duration))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(10)
                            .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    // 控制核心
                    CallControlsView(
                        callType: self.callType,
                        isMuted: $isMuted,
                        isSpeakerOn: $isSpeakerOn,
                        isVideoOff: $isVideoOff,
                        onHangup: {
                            print("🔴 用户点击挂断")
                            self.cameraManager.stopSession()
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
            .zIndex(10) // 控件层永远压在所有人像图层之上
        }
        .onAppear {
            self.startCallFlow()
        }
        .onDisappear {
            self.cameraManager.stopSession()
        }
    }
    
    /// 💡 独立封装对调事件，使用高阶动画
    private func toggleVideoWindow() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            isLocalVideoMain.toggle()
        }
    }
    
    // MARK: - 🎨 对方画面模拟器
    private var remoteVideoViewMock: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: isLocalVideoMain ? 30 : 60))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(chatName)
                    .font(isLocalVideoMain ? .caption : .headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
            }
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
        if callManager.isCallConnected {
            self.callState = .connected
            if self.callType == .video { self.cameraManager.setupCamera() }
            return
        }
        
        if self.callType == .video { self.cameraManager.setupCamera() }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard callManager.currentMode == .fullScreen else {
                callManager.isCallConnected = true
                return
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.callState = .connected
            }
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


enum CallState {
    case dialing
    case connected
}
