import SwiftUI

struct ImageMessageBubble: View {
    let msg: Message
    var onPreview: (Message) -> Void
    
    @State private var displayImage: UIImage? = nil
    @State private var isLoading = false
    
    init(msg: Message) {
        self.msg = msg
        self.onPreview = { _ in }
    }
    
    func onPreview(_ action: @escaping (Message) -> Void) -> Self {
        var copy = self
        copy.onPreview = action
        return copy
    }
    
    var body: some View {
        ZStack {
            if let uiImage = displayImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // 占位块
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .opacity(isLoading ? 1 : 0)
                    )
            }
        }
        .frame(width: 200, height: 200)
        .cornerRadius(10)
        .onTapGesture { onPreview(msg) }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // 如果已经加载过，直接返回
        if displayImage != nil { return }
        
        isLoading = true
        
        // 在后台线程进行降采样处理
        let image = await Task.detached(priority: .userInitiated) {
            // 目标尺寸 200x200
            return await ImageCacheManager.shared.image(forKey: msg.id.uuidString, targetSize: CGSize(width: 200, height: 200))
        }.value
        
        await MainActor.run {
            withAnimation(.easeIn(duration: 0.2)) {
                self.displayImage = image
                self.isLoading = false
            }
        }
        
        // 兜底逻辑：如果缓存里没找到（比如刚发的消息还没写完磁盘），则回退到直接解析 Data
        if displayImage == nil, let data = msg.imageData {
             if let fallbackImage = UIImage(data: data) {
                 await MainActor.run {
                     self.displayImage = fallbackImage
                 }
             }
        }
    }
}

