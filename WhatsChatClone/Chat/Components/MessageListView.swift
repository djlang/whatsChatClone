import SwiftUI

struct MessageListView: View {
    let messages: [Message]
    let chatName: String
    let audioPlayerManager: AudioPlayerManager
    @Binding var previewMessage: Message?
    @Binding var isShowingAttachment: Bool

    // MARK: - 分页相关
    var hasMoreMessages: Bool
    var isLoadingMore: Bool
    var onLoadMore: () -> Void

    var onDismissInput: () -> Void
    var onDeleteMessage: (Message) -> Void
    var onPlayVideo: (Message) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    
                    // 💡 分页加载检测器
                    if hasMoreMessages {
                        HStack {
                            Spacer()
                            if isLoadingMore {
                                ProgressView()
                                    .padding(.vertical, 20)
                            } else {
                                Color.clear
                                    .frame(height: 20)
                                    .onAppear {
                                        onLoadMore()
                                    }
                            }
                            Spacer()
                        }
                    }
                    
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                        messageRow(at: index, message: msg)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            // ❌ 移除 .defaultScrollAnchor(.bottom)，它是导致加载旧消息时回跳底部的元凶
            .scrollDismissesKeyboard(.interactively)
            .background(Color.waBackground)
            .onTapGesture {
                onDismissInput()
            }
            // 1. 发新消息时滚动
            .onChange(of: messages.count) { oldVal, newVal in
                // 💡 只有当是真正的“新消息”增加时（不是加载更多导致）才自动滚到底部
                if newVal > oldVal && !isLoadingMore {
                    scrollToBottom(proxy: proxy)
                }
            }
            .onAppear {
                // 首次进入：直接定位到最新消息
                if let lastId = messages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottom(proxy: proxy)
                }
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
