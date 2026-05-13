import SwiftUI
import SwiftData
import ZLPhotoBrowser
import PhotosUI

struct ChatDetailView: View {
    var chat: ChatSummary
    
    // 1. 获取数据库上下文
    @Environment(\.modelContext) private var modelContext
    
    // 2. 自动从数据库实时抓取消息（按时间升序）
    @Query(sort: \Message.timestamp, order: .forward) var messages: [Message]
    
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
                viewModel = ChatViewModel(modelContext: modelContext)
                print("DEBUG: ViewModel 已成功初始化")
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
            
            TextField("输入消息...", text: $inputText)
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
    }
}
