//
//  LiveStreamManager.swift
//  WhatsChatClone
//
//  Created by Gemini CLI on 2026/5/29.
////
//
//import Foundation
//import HaishinKit
//import RTMPHaishinKit
//import SwiftUI
//import Combine
//
//class LiveStreamManager: NSObject, ObservableObject {
//    let rtmpConnection = RTMPConnection()
//    @Published var rtmpStream: RTMPStream?
//    
//    // Callback for status updates
//    var onStatusChange: ((String) -> Void)?
//    
//    override init() {
//        super.init()
//        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(onStatus), observer: self)
//    }
//    
//    deinit {
//        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(onStatus), observer: self)
//    }
//    
//    @objc private func onStatus(_ notification: Notification) {
//        let e = Event.from(notification)
//        guard let data = e.data as? ASObject, let code = data["code"] as? String else { return }
//        onStatusChange?(code)
//    }
//}
