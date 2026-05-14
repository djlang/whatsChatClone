//
//  WhatsChatCloneApp.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import SwiftUI
import SwiftData

@main
struct WhatsChatCloneApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabBarView()
        }
        .modelContainer(for: [ChatSummary.self, Message.self])
    }
}
