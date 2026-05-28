import SwiftUI
import SwiftData
import ZLPhotoBrowser
import PhotosUI
import AVKit

struct ChatDetailView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    
    var chat: ChatSummary
    
    // 1. 获取数据库上下文
    @Environment(\.modelContext) private var modelContext
    
    // 2. 自动从数据库实时抓取消息（按时间升序）
    @Query var messages: [Message]
    
    // 3. 状态管理
    @State private var isShowingAttachment: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedLocationMessage: Message? = nil
    
    // 预览相关状态
    @State private var previewMessage: Message? = nil
    // 键盘与滚动状态
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var viewModel: ChatViewModel?
    
    //通话状态
    @State private var activeCallType: CallType? = nil // 记录当前激活动态：语音还是视频
    
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

    // MARK: - 主视图
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 主内容层
                MessageListView(
                    messages: viewModel?.currentChat.messages ?? [],
                    chatName: viewModel?.currentChat.name ?? "",
                    audioPlayerManager: audioPlayerManager,
                    previewMessage: $previewMessage,
                    isShowingAttachment: $isShowingAttachment,
                    onDismissInput: { self.dismissInput() },
                    onDeleteMessage: { self.deleteMessage($0) },
                    onPlayVideo: { self.playVideo(msg: $0) }
                )
                
                // --- 录音全屏遮罩层 ---
                if let vm = viewModel, vm.isRecordingVoice {
                    VoiceRecordingOverlayView(isCancelled: vm.isRecordingCancelled, audioLevel: vm.voiceAudioLevel)
                        .transition(.opacity.animation(.easeInOut(duration: 0.15)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 物理占据空间的底部工具栏
            bottomToolBar
                .padding(.bottom, isInputFocused ? 0 : 0) // 键盘弹出时，由键盘避让自动处理，或者手动补偿
        }
        .background(waBackground.ignoresSafeArea())
        // 关键：由于我们要手动精确控制布局，有时需要禁止系统的自动避让来防止双重偏移
        // .ignoresSafeArea(.keyboard, edges: .bottom) 
        ///导航栏按钮组
        .applyChatNavigationConfiguration(name: chat.name, trailingToolbar: chatTrailingToolbar())
        //全屏弹窗与遮罩
        .applyChatOverlays(
            previewMessage: $previewMessage,
            selectedLocationMessage: $selectedLocationMessage,
            chatName: chat.name
        )
        .setupChatBusinessLogic(
            isInputFocused: $isInputFocused,
            isShowingAttachment: $isShowingAttachment,
            keyboardHeight: $keyboardHeight,
            activeCallType: $activeCallType,
            audioPlayerManager: audioPlayerManager,
            locationManager: locationManager,
            viewModel: $viewModel,
            chat: chat,
            modelContext: modelContext
        )
    }
    
    // MARK: - 子视图提取 2: 底部输入功能栏
    private var bottomToolBar: some View {
        VStack(spacing: 0) {
            if let vm = viewModel {
                InputBarView(
                    inputText: Bindable(vm).inputText,
                    isVoiceMode: Bindable(vm).isVoiceMode,
                    isInputFocused: $isInputFocused,
                    onToggleAttachment: {
                        self.toggleAttachment()
                    },
                    onSendMessage: {
                        self.viewModel?.sendMessage(type: "text", text: vm.inputText)
                        vm.inputText = ""
                    },
                    onToggleVoiceMode: {
                        withAnimation(.spring(response: 0.3)) {
                            vm.isVoiceMode.toggle()
                            if vm.isVoiceMode {
                                self.dismissInput()
                            } else {
                                self.isInputFocused = true
                            }
                        }
                    },
                    onRecordComplete: { data, duration in
                        self.viewModel?.sendMessage(type: "voice", voiceData: data, voiceDuration: duration)
                    },
                    isRecordingVoice: Bindable(vm).isRecordingVoice,
                    isRecordingCancelled: Bindable(vm).isRecordingCancelled,
                    voiceAudioLevel: Bindable(vm).voiceAudioLevel
                )
                .background(keyboardLikeBackground)
            }
            
            // 附件栏明细
            if isShowingAttachment {
                AttachmentGridView(
                    selectedItem: $selectedPhotoItem,
                    onTriggerPicker: {
                        self.openZLPhotoPicker()
                    },
                    onTriggerLocation: {
                        withAnimation {
                            self.isShowingAttachment = false
                        }
                        self.locationManager.requestLocation()
                    }
                )
                .frame(height: 250)
                .background(keyboardLikeBackground)
                .transition(.move(edge: .bottom))
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
        }
    }
    
    private func deleteMessage(_ msg: Message) {
        let summary = msg.chatSummary
        modelContext.delete(msg)
        
        if let summary = summary {
            let remainingMessages = summary.messages?.filter { $0.id != msg.id }
            if let lastRemaining = remainingMessages?.sorted(by: { $0.timestamp < $1.timestamp }).last {
                summary.lastMessage = lastRemaining.text
                summary.lastTimestamp = lastRemaining.timestamp
            } else {
                summary.lastMessage = "暂无消息"
            }
        }
        try? modelContext.save()
    }
}

// MARK: - 📸 媒体处理扩展 (相册选择与视频播放)
extension ChatDetailView {
    
    func openZLPhotoPicker() {
        let picker = ZLPhotoPicker()
        picker.selectImageBlock = { results, isOriginal in
            for result in results {
                let asset = result.asset
                if asset.mediaType == .video {
                    if let thumbData = result.image.jpegData(compressionQuality: 0.6) {
                        self.viewModel?.handleVideoSelection(asset: asset, thumbnailData: thumbData)
                    }
                } else {
                    if let data = result.image.jpegData(compressionQuality: 0.8) {
                        self.viewModel?.sendMessage(type: "image", imageData: data)
                    }
                }
            }
            DispatchQueue.main.async { self.dismissInput() }
        }
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        picker.showPhotoLibrary(sender: rootVC)
    }

    func playVideo(msg: Message) {
        guard let videoData = msg.videoData else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_video.mp4")
        try? videoData.write(to: tempURL)
        
        let player = AVPlayer(url: tempURL)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.allowsVideoFrameAnalysis = false
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        
        rootVC.present(playerVC, animated: true) {
            player.play()
        }
    }
}

extension View {
    /// 封装聊天页面的导航栏与工具栏配置
    func applyChatNavigationConfiguration(name: String, trailingToolbar: some ToolbarContent) -> some View {
        self
            .navigationTitle(name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { trailingToolbar }
            .toolbar(.hidden, for: .tabBar)
            .toolbarBackground(Color(UIColor.systemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
    }
    
    /// 封装聊天页面的全屏弹窗与遮罩
    func applyChatOverlays(
        previewMessage: Binding<Message?>,
        selectedLocationMessage: Binding<Message?>,
        chatName: String,
    ) -> some View {
        self
            .fullScreenCover(item: previewMessage) { message in
                if let data = message.imageData, let uiImage = UIImage(data: data) {
                    ImageDetailView(image: uiImage)
                }
            }
            .fullScreenCover(item: selectedLocationMessage) { msg in
                LocationFullScreenView(msg: msg)
            }
    }
    
    /// 封装聊天页面的业务逻辑监听
    func setupChatBusinessLogic(
        isInputFocused: FocusState<Bool>.Binding,
        isShowingAttachment: Binding<Bool>,
        keyboardHeight: Binding<CGFloat>,
        activeCallType: Binding<CallType?>,
        audioPlayerManager: AudioPlayerManager,
        locationManager: LocationManager,
        viewModel: Binding<ChatViewModel?>,
        chat: ChatSummary,
        modelContext: ModelContext
    ) -> some View {
        self
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight.wrappedValue = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight.wrappedValue = 0
                }
            }
            .onChange(of: isInputFocused.wrappedValue) { _, newValue in
                if newValue {
                    withAnimation {
                        isShowingAttachment.wrappedValue = false
                    }
                }
            }
            .onChange(of: activeCallType.wrappedValue) { _, newValue in
                if newValue != nil {
                    // 只要通话界面准备弹出，就停止当前消息播放
                    audioPlayerManager.stopPlaying()
                }
            }
            .onChange(of: locationManager.location) { _, newLoc in
                if let loc = newLoc {
                    viewModel.wrappedValue?.sendLocationMessage(loc)
                }
            }
            .onAppear {
                
                if viewModel.wrappedValue == nil {
                    viewModel.wrappedValue = ChatViewModel(modelContext: modelContext, chat: chat)
                
                }
                viewModel.wrappedValue?.isViewingChat = true
                if chat.unreadCount > 0 {
                    chat.unreadCount = 0
                    try? modelContext.save()
                }
            }
            .onDisappear {
                viewModel.wrappedValue?.isViewingChat = false
            }
    }
}

extension ChatDetailView {
    
    // 💡 抽离导航栏按钮组
    @ToolbarContentBuilder
    private func chatTrailingToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(action: { OverlayCallManager.shared.startCall(with: self.chat, type: .audio)}) {
                    Label("语音通话", systemImage: "phone")
                }
                Button(action: { OverlayCallManager.shared.startCall(with: self.chat, type: .video)}) {
                    Label("视频通话", systemImage: "video")
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "phone").font(.system(size: 16, weight: .medium))
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold)).foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }
}
