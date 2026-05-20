//
//  AudioPlayerManager.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/20.
//

import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentlyPlayingMessageId: UUID? = nil
    
    private var audioPlayer: AVAudioPlayer?
    
    func playVoice(data: Data, messageId: UUID) {
        // 如果点击的是正在播放的语音，则停止
        if isPlaying && currentlyPlayingMessageId == messageId {
            stopPlaying()
            return
        }
        
        // 逻辑 B：如果有其他的在播，先杀掉之前的进程
        if currentlyPlayingMessageId != nil {
            stopPlaying()
        }
        
        do {
            // 配置音频会话，确保声音从扬声器发出
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            currentlyPlayingMessageId = messageId
            isPlaying = true
            audioPlayer?.play()
        } catch {
            print("语音播放失败: \(error)")
        }
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
        currentlyPlayingMessageId = nil
    }
    
    // 播放完成的回调
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentlyPlayingMessageId = nil
            print("DEBUG: 播放完成，已重置播放ID")
        }
    }
}
