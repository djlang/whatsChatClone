//
//  LiveStreamManager.swift
//  WhatsChatClone
//
//  Created by Gemini CLI on 2026/5/29.
//

import Foundation
import HaishinKit
import RTMPHaishinKit
import SwiftUI
import Combine

class LiveStreamManager: NSObject, ObservableObject, MTHKViewRepresentable.PreviewSource {
    let mixer = MediaMixer()
    let rtmpConnection = RTMPConnection()
    @Published var rtmpStream: RTMPStream?
    
    // Callback for status updates
    var onStatusChange: ((String) -> Void)?
    
    private var statusTask: Task<Void, Never>?

    override init() {
        super.init()
        setupEventHandling()
    }
    
    deinit {
        statusTask?.cancel()
    }
    
    // Implementation of MTHKViewRepresentable.PreviewSource
    func connect(to view: MTHKView) {
        Task { @MainActor in
            await mixer.addOutput(view)
        }
    }
    
    private func setupEventHandling() {
        statusTask = Task {
            for await status in rtmpConnection.status {
                // Handle status changes here
                onStatusChange?(status.code)
            }
        }
    }
}
