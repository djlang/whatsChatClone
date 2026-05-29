//
//  AnchorLiveView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/29.
//

import SwiftUI
import AVFoundation
import HaishinKit
import RTMPHaishinKit
import CoreLocation
import Combine

struct AnchorLiveView: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var streamManager = LiveStreamManager()
    @State private var isPublishing = false
    
    // 💡 替换为你 Mac Mini 的局域网 IP（如果用模拟器跑，可以直接写 localhost）
    let srsPushURL = "rtmp://192.168.5.133/live/"
    let streamKey = "room1"
    
//    private var rtmpStream: RTMPStream?
//    private var mediaMixer = MediaMixer()

    var body: some View {
        ZStack {
            // 🔴 1. 主播镜头预览层（底层）
            // 使用 HaishinKit 2.x 的 SwiftUI 包装视图
            MTHKViewRepresentable(previewSource: streamManager, videoGravity: .resizeAspectFill)
                .ignoresSafeArea()
            
            // 🔴 2. 顶层控制面板
            VStack {
                HStack {
                    Button {
                        stopLive()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                    
                    // 切换前后摄像头
                    Button {
                        // 逻辑需根据 HaishinKit 2.x Mixer API 调整
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal)
                
                Spacer()
                
                // 🔴 3. 一键开播按钮
                Button {
                    Task {
                        if isPublishing {
                            stopLive()
                        } else {
                            await startLive()
                        }
                    }
                } label: {
                    Text(isPublishing ? "结束直播" : "开始一键开播")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isPublishing ? Color.red : Color.green)
                        .cornerRadius(25)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            setupCameraAndStream()
            streamManager.onStatusChange = { code in
                Task { @MainActor in
                    await handleStatus(code: code)
                }
            }
        }
        .onDisappear {
            stopLive()
        }
    }
}

// MARK: - HaishinKit 音视频流初始化
extension AnchorLiveView {
    
    private func setupCameraAndStream() {
        // 1. 初始化专属 RTMP 传输流
        let stream = RTMPStream(connection: streamManager.rtmpConnection)
        
        // 2. 提取硬件传感器
        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        let defaultMicrophone = AVCaptureDevice.default(for: .audio)
        
        // 3. 异步配置多媒体硬件与编码器参数
        Task {
            do {
                // 🟢 绑定到 Mixer (HaishinKit 2.x)
                try await streamManager.mixer.attachVideo(frontCamera, track: 0)
                try await streamManager.mixer.attachAudio(defaultMicrophone, track: 0)
                
                // 🟢 启动 Mixer 运行
                try await streamManager.mixer.startRunning()
                
                // 🟢 编码器参数
                try await stream.setVideoSettings(.init(
                    videoSize: .init(width: 720, height: 1280),
                    bitRate: 1500 * 1000
                ))
                
                // 音频设置
                try await stream.setAudioSettings(.init(
                    bitRate: 64 * 1000
                ))
                
                print("🍏 硬件双路绑定与编码器参数优化成功！")
            } catch {
                print("❌ 初始化失败: \(error)")
            }
        }
        
        streamManager.rtmpStream = stream
    }
    
    private func startLive() async {
        // 异步连接
        do {
            _ = try await streamManager.rtmpConnection.connect(srsPushURL)
            isPublishing = true
        } catch {
            print("❌ 连接失败: \(error)")
        }
    }
    
    private func stopLive() {
        Task {
            _ = try? await streamManager.rtmpStream?.close()
            _ = try? await streamManager.rtmpConnection.close()
            isPublishing = false
        }
    }
    
    @MainActor
    private func handleStatus(code: String) async {
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            // 后台 API 连接成功，开始向 room1 频道灌入音视频数据
            _ = try? await streamManager.rtmpStream?.publish(streamKey)
            print("🚀 主播端推流成功！音视频数据已实时上传至本地开源后台")
        default:
            break
        }
    }
}
