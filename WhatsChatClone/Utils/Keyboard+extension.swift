//
//  Keyboard+extension.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        // 通过发送通知给 UIApplication 来让所有输入框放弃“第一响应者”身份
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
