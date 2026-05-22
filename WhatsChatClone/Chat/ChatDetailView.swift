import SwiftUI
import SwiftData
import ZLPhotoBrowser
import PhotosUI
import AVKit


/// 通话类型枚举
enum CallType: String, Identifiable {
    case audio = "语音通话"
    case video = "视频通话"
    
    // 实现 Identifiable 协议，方便 fullScreenCover 监听
    var id: String { self.rawValue }
}

struct ChatDetailView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    
    @State private var isVoiceMode: Bool = false
    @State private var isRecordingVoice: Bool = false
    @State private var isRecordingCancelled: Bool = false // 记录手势是否滑到了取消区
    @State private var voiceAudioLevel: Float = 0
    
    var chat: ChatSummary
    
    // 1. 获取数据库上下文
    @Environment(\.modelContext) private var modelContext
    
    // 2. 自动从数据库实时抓取消息（按时间升序）
    @Query var messages: [Message]
    
    // 3. 状态管理
    @State private var inputText = ""
    @State private var isShowingAttachment: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedLocationMessage: Message? = nil
    
    // 预览相关状态
    @State private var previewMessage: Message? = nil
    // 键盘与滚动状态
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollTrigger: Int = 0
    
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
        ZStack {
            // 主内容层：只放一个骨架，内部逻辑全部抽离
            VStack(spacing: 0) {
                messageListView
            }
            
            // --- 录音全屏遮罩层 ---
            if isRecordingVoice {
                // 关键点：将 voiceAudioLevel 注入进 Overlay，使波纹能实时变动
                VoiceRecordingOverlayView(isCancelled: isRecordingCancelled, audioLevel: voiceAudioLevel)
                    .transition(.opacity.animation(.easeInOut(duration: 0.15))) // 丝滑淡入淡出
            }
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        // ---- 添加以下 toolbar 代码 ----
        .toolbar(content: chatTrailingToolbar)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(keyboardLikeBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            bottomToolBar
        }
        // 全屏图片预览
        .fullScreenCover(item: $previewMessage) { message in
            if let data = message.imageData, let uiImage = UIImage(data: data) {
                ImageDetailView(image: uiImage)
            }
        }
        .fullScreenCover(item: $activeCallType) { callType in
            // 这里是未来我们高仿的全屏通话大界面，现在先放一个临时占位，确保链路畅通
            MockCallOverlayView(callType: callType) { duration in
                // 这里是挂断后的回调，未来在这里落盘 SwiftData 数据库
                print("通话结束，时长：\(duration)秒")
            }
        }
        // 键盘与系统回调监听
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
        .onChange(of: locationManager.location) { _, newLoc in
            if let loc = newLoc {
                sendLocationMessage(loc)
            }
        }
        .onAppear {
            if viewModel == nil {
                print("DEBUG: ViewModel 已成功初始化")
                viewModel = ChatViewModel(modelContext: modelContext, chat: chat)
            }
            if chat.unreadCount > 0 {
                chat.unreadCount = 0
                try? modelContext.save()
            }
        }
        .fullScreenCover(item: $selectedLocationMessage) { msg in
            LocationFullScreenView(msg: msg)
        }
    }
    
    // MARK: - 子视图提取 1: 消息历史滚动列表
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                        
                        if index == 0 || !isSameDay(date1: messages[index - 1].timestamp, date2: msg.timestamp) {
                            Text(dateHeader(for: msg.timestamp))
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
                            onDelete: { deleteMessage(msg) },
                            onPlayVideo: { playVideo(msg: $0) },
                            onPreviewImage: { previewMessage = $0 },
                            audioPlayerManager: audioPlayerManager
                        )
                        .id(msg.id)
                        .overlay(alignment: msg.isFromMe ? .leading : .trailing) {
                            if msg.isSending {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(msg.isFromMe ? .leading : .trailing, -30) // 把小菊花推到气泡的外面空白处
                            }
                        }
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
            // 修正为现代 SwiftUI 规格的双参数闭包，降低推导负担
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy: proxy) }
            .onChange(of: scrollTrigger) { _, _ in scrollToBottom(proxy: proxy) }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }
    
    // MARK: - 子视图提取 2: 底部输入功能栏
    private var bottomToolBar: some View {
        VStack(spacing: 0) {
            InputBarView(
                inputText: $inputText,
                isVoiceMode: $isVoiceMode,
                isInputFocused: $isInputFocused,
                onToggleAttachment: {
                    toggleAttachment()
                },
                onSendMessage: {
                    viewModel?.sendMessage(type: "text", text: inputText)
                    inputText = ""
                },
                onToggleVoiceMode: {
                    withAnimation(.spring(response: 0.3)) {
                        isVoiceMode.toggle()
                        if isVoiceMode {
                            dismissInput()
                        } else {
                            isInputFocused = true
                        }
                    }
                },
                onRecordComplete: { data, duration in
                    viewModel?.sendMessage(type: "voice", voiceData: data, voiceDuration: duration)
                },
                isRecordingVoice: $isRecordingVoice,
                isRecordingCancelled: $isRecordingCancelled,
                voiceAudioLevel: $voiceAudioLevel
            )
            .background(keyboardLikeBackground)
            
            // 附件栏明细
            if isShowingAttachment {
                AttachmentGridView(
                    selectedItem: $selectedPhotoItem,
                    onTriggerPicker: {
                        self.openZLPhotoPicker()
                    },
                    onTriggerLocation: {
                        withAnimation {
                            isShowingAttachment = false
                        }
                        locationManager.requestLocation()
                    }
                )
                .frame(height: 250)
                .background(keyboardLikeBackground)
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    // MARK: - 业务逻辑辅助方法
    private func sendLocationMessage(_ loc: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) { placemarks, error in
            let address = placemarks?.first?.name ?? "未知地点"
            DispatchQueue.main.async {
                viewModel?.sendMessage(type: "location", text: nil, imageData: nil, latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, locationName: address)
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
        let picker = ZLPhotoPicker()
        picker.selectImageBlock = { results, isOriginal in
            for result in results {
                let asset = result.asset
                if asset.mediaType == .video {
                    if let thumbData = result.image.jpegData(compressionQuality: 0.6) {
                        self.handleVideoSelection(asset: asset, thumbnailData: thumbData)
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

    private func handleVideoSelection(asset: PHAsset, thumbnailData: Data) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, _) in
            guard let urlAsset = avAsset as? AVURLAsset else { return }
            let videoURL = urlAsset.url
            
            MediaService.shared.compressVideo(inputURL: videoURL) { compressedData in
                guard let data = compressedData else { return }
                DispatchQueue.main.async {
                    self.viewModel?.sendMessage(type: "video", imageData: thumbnailData, videoData: data)
                }
            }
        }
    }
    
    private func playVideo(msg: Message) {
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
    
    private func saveToGallery(msg: Message) {
        MediaService.shared.saveToGallery(msg: msg)
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
    
    private func dateHeader(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: date)
        }
    }

    private func isSameDay(date1: Date, date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}



extension ChatDetailView {
    
    // 💡 抽离导航栏按钮组
    @ToolbarContentBuilder
    private func chatTrailingToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(action: { activeCallType = .audio }) {
                    Label("语音通话", systemImage: "phone")
                }
                Button(action: { activeCallType = .video }) {
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
