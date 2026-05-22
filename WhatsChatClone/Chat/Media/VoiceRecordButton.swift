//
//  VoiceRecordButton.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/20.
//
import SwiftUI
import Combine

struct VoiceRecordButton: View {
    @StateObject private var recorder = VoiceRecorder()
    @Binding var isRecording: Bool
    @Binding var isCancelled: Bool
    
    @Binding var audioLevel: Float // 接收这个 Binding
    @State private var timer: Timer? = nil
    
    var onRecordComplete: (Data, Double) -> Void
    
    var body: some View {
        Text(isRecording ? (isCancelled ? "松开 取消" : "松开 发送") : "按住 说话")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isRecording ? Color.gray.opacity(0.3) : Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isRecording {
                            isRecording = true
                            isCancelled = false
                            HapticManager.shared.triggerImpact(style: .medium) // <-- 震动反馈：指尖一麻，开始录音
                            recorder.startRecording()
                            
                            // 启动定时器，每 0.1 秒更新一次音量
                            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                                withAnimation(.linear(duration: 0.1)) {
                                    self.audioLevel = recorder.getAveragePower()
                                }
                            }
                        }
                        
                        
                        //2. 核心优化：往上滑动超过 50 像素判断
                        let newCancelledState = value.translation.height < -50
                        
                        // 临界点拦截：只有当“是否取消”的状态真正发生改变时，才触发一次轻微震动
                        if newCancelledState != isCancelled {
                            isCancelled = newCancelledState
                            
                            // 指尖轻轻“哒”一声，高级感就在这一个小动作里
                            HapticManager.shared.triggerImpact(style: .light)
                        }
                    }
                    .onEnded { _ in
                        isRecording = false
                        let result = recorder.stopRecording()
                        
                        if isCancelled {
                            print("用户上滑取消了录音")
                        } else if let result = result {
                            // 成功录制，回调传出
                            onRecordComplete(result.data, result.duration)
                        } else {
                            print("录音时间太短")
                        }
                        
                        isRecording = false
                        isCancelled = false
                        
                        timer?.invalidate()
                        timer = nil
                        audioLevel = 0.1
                    }
            )
    }
}
