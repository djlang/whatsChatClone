//
//  ChatListView.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/12.
//

import SwiftUI

struct ChatListView: View {
    var body: some View {
        NavigationStack {
            List(sampleChats) { chat in
                NavigationLink(destination: ChatDetailView(chat: chat)) {
                    HStack(spacing: 15) {
                        Image(systemName: chat.avatar)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(chat.name).font(.headline)
                                Spacer()
                                Text(chat.time).font(.subheadline).foregroundColor(.gray)
                            }
                            Text(chat.lastMessage)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.plain)
            .navigationTitle("聊天")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "camera")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }
}
