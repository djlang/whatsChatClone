import SwiftUI
import SwiftData
import ZLPhotoBrowser
import PhotosUI

struct ChatDetailView: View {
    var chat: ChatSummary
    
    // 1. 获取数据库上下文
    @Environment(\.modelContext) private var modelContext
    
    // 2. 自动从数据库实时抓取消息（按时间升序）
//    @Query(sort: \Message.timestamp, order: .forward) var messages: [Message]
    // 关键：根据当前聊天对象的 id (或 name) 进行过滤
    @Query var messages: [Message]
    
    // 3. 状态管理
    @State private var inputText = ""
    @State private var isShowingAttachment: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // 预览相关状态
    @State private var previewMessage: Message? = nil
    // 键盘与滚动状态
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollTrigger: Int = 0
    
    
    @State private var viewModel: ChatViewModel?
    // WhatsApp 颜色
    let waGreen = Color(red: 0.88, green: 0.99, blue: 0.78)
    let waBackground = Color(red: 0.94, green: 0.91, blue: 0.88)
    let keyboardLikeBackground = Color(UIColor.systemGroupedBackground)
    
    init(chat: ChatSummary) {
        self.chat = chat
        
        let targetID = chat.id
        _messages = Query(
            filter: #Predicate<Message> { $0.chatSummary?.id == targetID },
            sort: \Message.timestamp,
            order: .forward
        )
    }

    // 统一收起逻辑
    private func dismissInput() {
        isInputFocused = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowingAttachment = false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        // 使用从数据库查询到的 messages
                        ForEach(messages) { message in
                            chatBubble(msg: message).id(message.id)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .simultaneousGesture(DragGesture().onChanged { _ in
                        dismissInput()
                    })
                }
                .scrollDismissesKeyboard(.interactively)
                .background(waBackground)
                .onTapGesture {
                    dismissInput()
                }
                // 当数据库消息数量变化或滚动触发器改变时滚动
                .onChange(of: messages.count) { scrollToBottom(proxy: proxy) }
                .onChange(of: scrollTrigger) { _, _ in scrollToBottom(proxy: proxy) }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(keyboardLikeBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                inputBar.background(keyboardLikeBackground)
                if isShowingAttachment {
                    AttachmentGridView(selectedItem: $selectedPhotoItem, onTriggerPicker: {
                        self.openZLPhotoPicker()
                    })
                    .frame(height: 250)
                    .background(keyboardLikeBackground)
                    .transition(.move(edge: .bottom))
                }
            }
        }
        // 全屏图片预览
        .fullScreenCover(item: $previewMessage) { message in
            // 这里确保 Data 转 UIImage 成功后再渲染
            if let data = message.imageData, let uiImage = UIImage(data: data) {
                ImageDetailView(image: uiImage)
            }
        }
        // 键盘监听逻辑
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                    scrollTrigger += 1
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        .onChange(of: isInputFocused) { _, newValue in
            if newValue { withAnimation { isShowingAttachment = false } }
        }
        .onAppear {
            if viewModel == nil {
//                viewModel = ChatViewModel(modelContext: modelContext, chatId: chat.id.uuidString)
                print("DEBUG: ViewModel 已成功初始化")
                viewModel = ChatViewModel(modelContext: modelContext, chat: chat)
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
    
    private func toggleAttachment() {
        if isShowingAttachment {
            isInputFocused = true
        } else {
            isInputFocused = false
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isShowingAttachment = true
            }
            scrollTrigger += 1
        }
    }
    
    private func openZLPhotoPicker() {
        let picker = ZLPhotoPicker() // 如果报错，请确认版本类名
        picker.selectImageBlock = { results, isOriginal in
            for result in results {
                if let data = result.image.jpegData(compressionQuality: 0.8) {
                    self.viewModel?.sendImageMessage(imageData: data)
                }
            }
            DispatchQueue.main.async { self.dismissInput() }
        }
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        picker.showPhotoLibrary(sender: rootVC)
    }

    // --- 气泡组件 ---

    @ViewBuilder
    func chatBubble(msg: Message) -> some View {
        HStack {
            if msg.isFromMe { Spacer() }
            
            VStack(alignment: .trailing, spacing: 4) {
                if let imageData = msg.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .cornerRadius(10)
                        .onTapGesture {
                            if msg.imageData != nil {
                                self.previewMessage = msg // 只要赋值，cover 就会自动打开
                            }
                        }
                } else {
                    Text(msg.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                
                Text(msg.time)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
                    .padding(.bottom, 4)
            }
            .background(msg.isFromMe ? waGreen : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: msg.isFromMe ? .trailing : .leading)
            .contextMenu {
                // 复制按钮
                Button {
                    UIPasteboard.general.string = msg.text
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                }
                
                // 删除按钮（危险操作建议用 destructive）
                Button(role: .destructive) {
                    deleteMessage(msg)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
            
            if !msg.isFromMe { Spacer() }
        }
    }
    
    var inputBar: some View {
        HStack(spacing: 12) {
            Button(action: toggleAttachment) {
                Image(systemName: isShowingAttachment ? "keyboard" : "plus")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            TextField("输入消息...", text: $inputText, axis: .vertical)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            if !inputText.isEmpty {
                Button {
                    viewModel?.sendMessage(inputText) // 执行发送
                    inputText = "" // 清空输入框
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            } else {
                Image(systemName: "mic")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    
    private func deleteMessage(_ msg: Message) {
        // 1. 从数据库中移除
        let summary = msg.chatSummary
        modelContext.delete(msg)
        
        if let summary = summary {
            // 尝试获取该会话中 剩余的、时间最晚的一条消息
            // 注意：由于刚刚执行了 delete，我们需要从 summary.messages 里过滤掉当前这条
            let remainingMessages = summary.messages?.filter { $0.id != msg.id }
            
            if let lastRemaining = remainingMessages?.sorted(by: { $0.timestamp < $1.timestamp }).last {
                // 如果还有消息，就把预览更新为上一条
                summary.lastMessage = lastRemaining.text
                summary.lastTimestamp = lastRemaining.timestamp
            } else {
                // 如果消息删光了，清空预览
                summary.lastMessage = "暂无消息"
                // 时间可以保持不变，或者设为一个很早的时间
            }
        }
        // 2. 尝试保存
        try? modelContext.save()
        
     
    }
}
