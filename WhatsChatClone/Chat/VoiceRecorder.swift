//
//  VoiceRecorder.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/20.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

class VoiceRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var startTime: Date?
    
    // 开始录音
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        // 配置音频会话：支持录音和播放，声音从扬声器出来
        try? session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try? session.setActive(true)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_voice.m4a")
        
        // 微信同款高压缩比参数
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0, // 12kHz 足够人声
            AVNumberOfChannelsKey: 1,  // 单声道
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try? AVAudioRecorder(url: tempURL, settings: settings)
        audioRecorder?.record()
        startTime = Date()
    }
    
    // 停止录音并返回 (Data, 时长)
    func stopRecording() -> (data: Data, duration: Double)? {
        guard let recorder = audioRecorder, recorder.isRecording else { return nil }
        
        recorder.stop()
        let duration = Date().timeIntervalSince(startTime ?? Date())
        
        // 过滤掉小于 1 秒的无效录音（微信特色：录音时间太短）
        if duration < 1.0 {
            return nil
        }
        
        if let data = try? Data(contentsOf: recorder.url) {
            return (data, duration)
        }
        return nil
    }
}
