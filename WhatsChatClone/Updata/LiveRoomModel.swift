//
//  LiveRoomModel.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/29.
//

import Foundation
import SwiftUI

// MARK: - 辅助数据模型
struct LiveRoom: Identifiable {
    let id: String
    let title: String
    let streamer: String
    let coverImage: String
    let viewerCount: Int
    let streamURL: String
}
