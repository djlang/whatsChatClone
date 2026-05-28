import SwiftUI

struct MessageListView: View {
    let messages: [Message]
    let chatName: String
    let audioPlayerManager: AudioPlayerManager
    @Binding var previewMessage: Message?
    @Binding var isShowingAttachment: Bool

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
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(waBackground)
            .onTapGesture {
                onDismissInput()
            }
            // 1. 发新消息时滚动
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            // 2. 键盘弹出时滚动
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                // 延迟是为了等待系统键盘弹出导致容器高度变化后再对齐
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottom(proxy: proxy)
                }
            }
            // 3. 附件面板弹出时滚动
            .onChange(of: isShowingAttachment) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { value in
                        if abs(value.translation.height) > 10 {
                            onDismissInput()
                        }
                    }
            )
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
                chatName: chatName,
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
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastId = messages.last?.id else { return }
        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }
}
