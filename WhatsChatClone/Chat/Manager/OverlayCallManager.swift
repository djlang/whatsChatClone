//
//  OverlayCallManager.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/26.
//

import SwiftUI
import Combine

enum CallWindowMode {
    case fullScreen
    case minimized
    case closed
}

final class OverlayCallManager: ObservableObject {
    static let shared = OverlayCallManager()
    private init() {}
    
    @Published var currentMode: CallWindowMode = .closed
    @Published var activeChat: ChatSummary? = nil
    @Published var activeType: CallType = .video
    @Published var duration: TimeInterval = 0
    @Published var isCallConnected: Bool = false {
        didSet {
            if isCallConnected { startGlobalTimer() }
        }
    }
    
    private var timer: Timer?
    
    /// 发起通话
    func startCall(with chat: ChatSummary, type: CallType) {
        self.activeChat = chat
        self.activeType = type
        self.duration = 0
        self.isCallConnected = false
        withAnimation(.spring()) {
            self.currentMode = .fullScreen
        }
    }
    
    private func startGlobalTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.duration += 1
            }
        }
    }
    
    /// 挂断
    func endCall() {
        timer?.invalidate()
        timer = nil
        withAnimation(.spring()) {
            self.currentMode = .closed
        }
        self.activeChat = nil
        self.isCallConnected = false
    }
}
