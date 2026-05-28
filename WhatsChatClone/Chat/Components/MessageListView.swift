import SwiftUI

struct MessageListView: View {
    let messages: [Message]
    let chatName: String
    let audioPlayerManager: AudioPlayerManager
    @Binding var previewMessage: Message?
    @Binding var isShowingAttachment: Bool // 💡 新增：监听附件面板状态

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
            // 优化 2: 更加灵敏的滑动收起。使用 simultaneousGesture 配合 DragGesture
            .simultaneousGesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .local)
                    .onChanged { value in
                        // 如果用户有明显的垂直滑动位移，立即收起所有输入
                        if abs(value.translation.height) > 10 {
                            onDismissInput()
                        }
                    }
            )
            .scrollDismissesKeyboard(.interactively)
            .background(waBackground)
            .onTapGesture {
                onDismissInput()
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            // 💡 核心优化：当附件面板弹出或收起时，自动修正滚动位置
            .onChange(of: isShowingAttachment) { _, newValue in
                if newValue {
                    // 稍微延迟，等待面板弹出动画
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
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
