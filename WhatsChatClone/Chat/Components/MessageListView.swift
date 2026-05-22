import SwiftUI

struct MessageListView: View {
    let messages: [Message]
    let audioPlayerManager: AudioPlayerManager
    @Binding var previewMessage: Message?
    @Binding var scrollTrigger: Int
    
    var onDismissInput: () -> Void
    var onDeleteMessage: (Message) -> Void
    var onPlayVideo: (Message) -> Void
    
    let waBackground = Color(red: 0.94, green: 0.91, blue: 0.88)
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                        messageRow(at: index, message: msg)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .simultaneousGesture(DragGesture().onChanged { _ in
                    onDismissInput()
                })
            }
            .scrollDismissesKeyboard(.interactively)
            .background(waBackground)
            .onTapGesture {
                onDismissInput()
            }
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy: proxy) }
            .onChange(of: scrollTrigger) { _, _ in scrollToBottom(proxy: proxy) }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }

    @ViewBuilder
    private func messageRow(at index: Int, message msg: Message) -> some View {
        VStack(spacing: 12) {
            // 日期 Header 逻辑
            if index == 0 || !messages[index - 1].timestamp.isSameDay(as: msg.timestamp) {
                Text(msg.timestamp.chatDateHeader)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.vertical, 10)
            }
            
            ChatBubbleView(
                msg: msg,
                onDelete: { onDeleteMessage(msg) },
                onPlayVideo: { _ in onPlayVideo(msg) },
                onPreviewImage: { previewMessage = $0 },
                audioPlayerManager: audioPlayerManager
            )
            .id(msg.id)
            .overlay(alignment: msg.isFromMe ? .leading : .trailing) {
                if msg.isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(msg.isFromMe ? .leading : .trailing, -30)
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = messages.last?.id {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}
