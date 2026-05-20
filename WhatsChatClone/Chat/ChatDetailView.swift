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
                            
                            chatBubble(msg: msg).id(msg.id)
                                
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
                    AttachmentGridView(
                        selectedItem: $selectedPhotoItem, onTriggerPicker: {
                            self.openZLPhotoPicker()
                        },
                        onTriggerLocation: {
                            // 1. 先收起附件栏，像微信一样的交互
                            withAnimation {
                                isShowingAttachment = false
                            }
                            // 2. 发起定位请求
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

    // --- 气泡组件 ---

    @ViewBuilder
    func chatBubble(msg: Message) -> some View {
        HStack {
            if msg.isFromMe { Spacer() }
            
            VStack(alignment: msg.isFromMe ? .trailing : .leading, spacing: 4) {
                // --- 核心分类显示逻辑 ---
                messageContent(msg: msg)
                
                // --- 公共时间显示 ---
                Text(formatToTime(msg.timestamp)) // 统一使用 Date 转 String
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: msg.isFromMe ? .trailing : .leading)
            .contextMenu {
                // 1. 原有的复制功能（仅限文本）
                if msg.messageType == "text" {
                    Button {
                        UIPasteboard.general.string = msg.text
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                }

                // 2. 新增下载功能（仅限图片和视频）
                if msg.messageType == "image" || msg.messageType == "video" {
                    Button {
                        saveToGallery(msg: msg)
                        
                    } label: {
                        Label("保存到相册", systemImage: "square.and.arrow.down")
                    }
                }

                // 3. 原有的删除功能
                Button(role: .destructive) {
                    deleteMessage(msg)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
            
            if !msg.isFromMe { Spacer() }
        }
    }

    // 辅助函数：将 timestamp 转为 "14:20" 格式
    private func formatToTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 在 ChatDetailView 中添加一个专门负责内容分发的组件
    @ViewBuilder
    private func messageContent(msg: Message) -> some View {
        switch msg.messageType {
        case "image":
            if let imageData = msg.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .cornerRadius(10)
                    .onTapGesture { self.previewMessage = msg }
            }
        case "location":
            LocationMessageBubble(msg: msg)
                .onTapGesture {
                    self.selectedLocationMessage = msg
                }
        case "video":
            // 视频气泡展示逻辑
            VideoMessageBubble(msg: msg)
                .onTapGesture {
                    // 触发视频播放逻辑（下一步我们要实现的）
                    self.playVideo(msg: msg)
                }
        case "voice":
            VoiceMessageBubble(msg: msg, isPlaying: audioPlayerManager.currentlyPlayingMessageId == msg.id){
                if let data = msg.voiceData {
                    audioPlayerManager.playVoice(data: data, messageId: msg.id)
                }
            }
        default: // text
            Text(msg.text ?? "") // 建议使用可选解包
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(msg.isFromMe ? waGreen : Color.white)
                .cornerRadius(12)
        }
    }
    
    var inputBar: some View {
        HStack(spacing: 12) {
            Button(action: toggleAttachment) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            if isVoiceMode {
                VoiceRecordButton { data, duration in
                    viewModel?.sendMessage(type: "voice", voiceData: data, voiceDuration: duration)
                    
                }
                .frame(height: 40) // 与文字输入框高度保持近似
                .padding(.horizontal, 4)
            }else {
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
            }
            
           
            
            if !inputText.isEmpty  && !isVoiceMode{
                Button {
                    viewModel?.sendMessage(type: "text" ,text: inputText) // 执行发送
                    inputText = "" // 清空输入框
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            } else {
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isVoiceMode.toggle()
                        
                        if isVoiceMode {
                            // 切换到语音模式时，收起键盘和底部菜单
                            dismissInput()
                        } else {
                            // 切换回文本模式时，自动弹出键盘
                            isInputFocused = true
                        }
                    }
                } label: {
                    Image(systemName: isVoiceMode ? "keyboard" : "mic")
                        .foregroundColor(.blue)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                }
                
                
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
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
            self.compressVideo(inputURL: videoURL) { compressedData in
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
    
  
    private func compressVideo(inputURL: URL, completion: @escaping (Data?) -> Void) {
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        let asset = AVAsset(url: inputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                let data = try? Data(contentsOf: exportURL)
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
    
    private func saveToGallery(msg: Message) {
        if msg.messageType == "image", let data = msg.imageData, let image = UIImage(data: data) {
            // 保存图片
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            // 提示用户（可以加个简单的 Toast）
            print("图片已保存")
        }
        else if msg.messageType == "video", let videoData = msg.videoData {
            // 保存视频：需要先写成临时文件
            let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".mp4"
            let fileURL = URL(fileURLWithPath: tempPath)
            
            do {
                try videoData.write(to: fileURL)
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                }) { success, error in
                    if success {
                        print("视频保存成功")
                    } else {
                        print("保存失败: \(String(describing: error))")
                    }
                    // 清理临时文件
                    try? FileManager.default.removeItem(at: fileURL)
                }
            } catch {
                print("写入临时文件失败")
            }
        }
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
