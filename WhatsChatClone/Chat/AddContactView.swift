//
//  AddContactView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/14.
//
import SwiftUI
import SwiftData

struct AddContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "person.circle.fill"
    
    let icons = ["person.circle.fill", "person.badge.plus", "person.2.circle.fill", "star.circle.fill"]

    var body: some View {
        NavigationStack {
            Form {
                Section("联系人信息") {
                    TextField("输入名字", text: $name)
                }
                
                Section("选择头像") {
                    Picker("头像", selection: $selectedIcon) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("新增联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveContact()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveContact() {
        let newChat = ChatSummary(name: name, imageName: selectedIcon)
        modelContext.insert(newChat)
        // 方案 B 提醒：此时 messages 数组为空，首页会显示“暂无消息”
        try? modelContext.save()
        dismiss()
    }
}
