//
//  VoiceRecordButton.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/20.
//
import SwiftUI

struct VoiceRecordButton: View {
    @StateObject private var recorder = VoiceRecorder()
    @State private var isRecording = false
    @State private var isCancelled = false
    
    var onRecordComplete: (Data, Double) -> Void
    
    var body: some View {
        Text(isRecording ? (isCancelled ? "松开 取消" : "松开 结束") : "按住 说话")
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
                            recorder.startRecording()
                            // 可以在这里触发轻微震动反馈
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        
                        // 往上滑动超过 50 像素，判定为“想取消发送”
                        if value.translation.height < -50 {
                            isCancelled = true
                        } else {
                            isCancelled = false
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
                    }
            )
    }
}
