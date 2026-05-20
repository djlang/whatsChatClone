import SwiftUI
import SwiftData
import ZLPhotoBrowser
import PhotosUI
import AVKit
struct ChatDetailView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    
    @State private var isVoiceMode: Bool = false
    
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
    
    @State private var selectedLocationMessage: Message? = nil
    
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
                    LazyVStack(spacing: 12) {
                        // 使用从数据库查询到的 messages
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
                InputBarView(
                    inputText: $inputText,
                    isVoiceMode: $isVoiceMode,
                    isInputFocused: $isInputFocused,
                    onToggleAttachment: toggleAttachment,
                    onSendMessage: {
                        viewModel?.sendMessage(type: "text", text: inputText)
                        inputText = ""
                    },
                    onToggleVoiceMode: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isVoiceMode.toggle()
                            if isVoiceMode { dismissInput() } else { isInputFocused = true }
                        }
                    }
                )
                .background(keyboardLikeBackground)
                
                if isShowingAttachment {
                    AttachmentGridView(
                        selectedItem: $selectedPhotoItem,
                        onTriggerPicker: self.openZLPhotoPicker,
                        onTriggerLocation: {
                            withAnimation { isShowingAttachment = false }
                            locationManager.requestLocation()
                        }
                    )
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
        .onChange(of: locationManager.location) { oldLoc, newLoc in
            if let loc = newLoc {
                sendLocationMessage(loc)
            }
        }
        .onAppear {
            if viewModel == nil {
//                viewModel = ChatViewModel(modelContext: modelContext, chatId: chat.id.uuidString)
                print("DEBUG: ViewModel 已成功初始化")
                viewModel = ChatViewModel(modelContext: modelContext, chat: chat)
            }
            
            // 进入页面即表示已读
            if chat.unreadCount > 0 {
                chat.unreadCount = 0
                // 尝试保存状态
                try? modelContext.save()
            }
        }
        //打开地理位置
        .fullScreenCover(item: $selectedLocationMessage) { msg in
            LocationFullScreenView(msg: msg)
        }
    }
    
    
    private func sendLocationMessage(_ loc: CLLocation) {
        // 1. 构造地理位置消息（使用你刚才确认过的 Model 结构）
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) {placemarks, error in
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
        let picker = ZLPhotoPicker() // 如果报错，请确认版本类名
        picker.selectImageBlock = { results, isOriginal in
            for result in results {
                let asset = result.asset
                if asset.mediaType == .video {
                    // A. 处理视频
                    // 这里的 result.image 已经是 ZL 帮你生成好的视频封面图
                    if let thumbData = result.image.jpegData(compressionQuality: 0.6) {
                        self.handleVideoSelection(asset: asset, thumbnailData: thumbData)
                    }
                }else {
                    if let data = result.image.jpegData(compressionQuality: 0.8) {
    //                    self.viewModel?.sendImageMessage(imageData: data)
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


    //处理视频？
    private func handleVideoSelection(asset: PHAsset, thumbnailData: Data) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true // 允许从 iCloud 下载
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, _) in
            guard let urlAsset = avAsset as? AVURLAsset else { return }
            
            // 获取视频原始 URL
            let videoURL = urlAsset.url
            
            // 建议：进行一次简单的压缩，避免发送原始 4K 视频导致数据库爆炸
            MediaService.shared.compressVideo(inputURL: videoURL) { compressedData in
                guard let data = compressedData else { return }
                
                DispatchQueue.main.async {
                    // 发送视频消息：imageData 存封面，videoData 存视频
                    self.viewModel?.sendMessage(type: "video", imageData: thumbnailData, videoData: data)
                }
            }
        }
    }
    
    

    private func playVideo(msg: Message) {
        guard let videoData = msg.videoData else { return }
        
        // 1. 准备 URL
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_video.mp4")
        try? videoData.write(to: tempURL)
        
        // 2. 创建播放器
        let player = AVPlayer(url: tempURL)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.allowsVideoFrameAnalysis = false // 提高性能
        
        // 3. 弹出播放
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
    
    
    ///-------  时间相关  --------
    ///// 建议直接写在 ChatDetailView 的 private 扩展中
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
