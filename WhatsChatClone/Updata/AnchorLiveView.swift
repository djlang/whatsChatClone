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
    
    
    @State private var currentPosition: AVCaptureDevice.Position = .front // 默认是前置
    
    // 💡 替换为你 Mac Mini 的局域网 IP（如果用模拟器跑，可以直接写 localhost）
    let srsPushURL = "rtmp://192.168.234.1/live/"
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
                        toggleCamera()
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
            ///. 优先配置并激活音频状态机，扫清底层的 -19224 优先级警报/
        
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
// MARK: - HaishinKit 音视频流初始化
extension AnchorLiveView {
    
    // 🟢 调整配置时机，不再作为控制器孤立方法，而是在硬件准备好的瞬间强制激活
    private func forceActivateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // 强制覆盖，使用最高优先级的默认扬声器和录音模式
            try session.setCategory(.playAndRecord, mode: .videoChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("🍏 [时序同步] AVAudioSession 强制压制成功，彻底解除 -19224")
        } catch {
            print("❌ [时序同步] 失败: \(error)")
        }
    }
    
    private func setupCameraAndStream() {
        // 1. 初始化专属 RTMP 传输流
        let stream = RTMPStream(connection: streamManager.rtmpConnection)
        
        // 2. 提取硬件传感器
        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        let defaultMicrophone = AVCaptureDevice.default(for: .audio)
        
        // 3. 🟢 全线串行顺序执行，断绝“时空错位”
        Task {
            do {
                // A. 先由 Mixer 绑定硬件
                try await streamManager.mixer.attachVideo(frontCamera, track: 0)
                try await streamManager.mixer.attachAudio(defaultMicrophone, track: 0)
                
                await streamManager.mixer.addOutput(stream)
                
                // B. 🟢 在硬件挂载完的瞬间，紧接着强制再激活一次音频会话，覆盖掉 Mixer 的默认行为
                forceActivateAudioSession()
           
                // C. 启动 Mixer 运行
                try await streamManager.mixer.startRunning()
                
                // D. 编码器参数
                try await stream.setVideoSettings(.init(
                    videoSize: .init(width: 720, height: 1280),
                    bitRate: 1500 * 1000
                ))
                
                try await stream.setAudioSettings(.init(
                    bitRate: 64 * 1000
                ))
                
                print("🍏 [管道闭环] 硬件双路绑定与编码器参数优化成功！")
            } catch {
                print("❌ 初始化失败: \(error)")
            }
        }
        
        streamManager.rtmpStream = stream
    }
    
    // 🟢 优雅改动：让网络连接在主线程明确等待，确保硬件已经跑起来后再发起 connect
    private func startLive() async {
        // 先确保音频状态是 OK 的
        forceActivateAudioSession()
        
        do {
            print("📡 正在向 SRS 发起握手连接...")
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

extension AnchorLiveView {
    
    // 🟢 动态切换前后摄像头
    private func toggleCamera() {
        Task {
            // 1. 算出下一步要切换的方向
            let nextPosition: AVCaptureDevice.Position = (currentPosition == .front) ? .back : .front
            
            // 2. 获取目标方向的摄像头硬件
            guard let discoverDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: nextPosition) else {
                print("❌ 无法获取 \(nextPosition == .front ? "前置" : "后置") 摄像头")
                return
            }
            
            do {
                // 3. 🔴 核心：直接把新设备附加到相同的 track 0 上，Mixer 会自动无缝切换画面
                try await streamManager.mixer.attachVideo(discoverDevice, track: 0)
                
           
                // 4. 切换成功后，更新本地状态机
                await MainActor.run {
                    self.currentPosition = nextPosition
                }
                print("🍏 成功切换到: \(nextPosition == .front ? "前置摄像头" : "后置摄像头")")
            } catch {
                print("❌ 切换摄像头失败: \(error)")
            }
        }
    }
}
